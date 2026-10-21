import { useEffect, useState } from "react";
import {
  CalendarDays,
  CheckCircle2,
  Clock,
  History as HistoryIcon,
  Phone,
  ReceiptText,
  RefreshCcw,
  UserRound,
  Wallet,
} from "lucide-react";

import { getAgentTransactions } from "../../api/agentApi";
import { getCashTransferHistory } from "../../api/cashTransferApi";

export default function AgentHistory() {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    loadTransactions();
  }, []);

  // =====================================================
  // LOAD TRANSACTIONS
  // =====================================================

  async function loadTransactions() {
    try {
      setLoading(true);
      setError("");

      const [depositsRes, transfersRes] = await Promise.all([
        getAgentTransactions().catch(() => ({ data: [] })),
        getCashTransferHistory().catch(() => ({ data: [] })),
      ]);

      const deposits = (depositsRes?.data || []).map((d) => ({
        ...d,
        _displayType: "Cash Deposit",
        _displayId: d.transaction_id || d.id,
        _displayName: d.customer_name || "-",
        _displayPhone: d.customer_phone || "-",
        _displayAmount: d.amount,
        _displayBalance: d.balance_after,
        _displayStatus: d.status || "success",
        _displayDate: d.created_at,
      }));

      const transfers = (transfersRes?.data || []).map((t) => {
        // If it was claimed via agent and has a claimed_at date, it's likely a payout
        const isPayout = t.status === "claimed" && t.claim_method === "agent";
        return {
          ...t,
          _displayType: isPayout ? "Cash Payout" : "Cash Transfer",
          _displayId: t.transfer_id || t.code,
          _displayName: t.receiver_name || "-",
          _displayPhone: t.receiver_phone || "-",
          _displayAmount: t.amount,
          _displayBalance: null, // Transfers don't show a balance_after for the customer
          _displayStatus: t.status || "pending",
          _displayDate: t.created_at,
        };
      });

      const combined = [...deposits, ...transfers].sort((a, b) => {
        return new Date(b._displayDate || 0) - new Date(a._displayDate || 0);
      });

      setTransactions(combined);
    } catch (error) {
      console.error("AGENT HISTORY ERROR:", error);
      const detail = error.response?.data?.detail;
      setError(
        typeof detail === "string"
          ? detail
          : detail?.message || "Unable to load transactions"
      );
    } finally {
      setLoading(false);
    }
  }

  // =====================================================
  // TOTAL VOLUME
  // =====================================================

  const totalVolume = transactions.reduce(
    (total, item) => total + Number(item._displayAmount || 0),
    0
  );

  return (
    <>
      {/* HEADER */}
      <div className="mb-8 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">
            Transaction History
          </h1>
          <p className="mt-1 text-sm text-slate-500">
            View all your deposits, transfers, and payouts
          </p>
        </div>

        <button
          onClick={loadTransactions}
          disabled={loading}
          className="flex items-center gap-2 rounded-xl bg-blue-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-blue-700 disabled:opacity-50"
        >
          <RefreshCcw size={16} className={loading ? "animate-spin" : ""} />
          Refresh
        </button>
      </div>

      {error && (
        <div className="mb-6 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-600">
          {error}
        </div>
      )}

      {/* SUMMARY CARDS */}
      <div className="mb-6 grid gap-4 md:grid-cols-2">
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex items-center gap-4">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 text-blue-600">
              <ReceiptText size={24} />
            </div>
            <div>
              <p className="text-sm text-slate-500">Total Transactions</p>
              <h2 className="mt-1 text-2xl font-bold text-slate-900">
                {transactions.length}
              </h2>
            </div>
          </div>
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex items-center gap-4">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-green-50 text-green-600">
              <Wallet size={24} />
            </div>
            <div>
              <p className="text-sm text-slate-500">Total Volume</p>
              <h2 className="mt-1 text-2xl font-bold text-slate-900">
                $
                {totalVolume.toLocaleString(undefined, {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2,
                })}
              </h2>
            </div>
          </div>
        </div>
      </div>

      {/* TRANSACTIONS TABLE */}
      <div className="rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="border-b border-slate-100 p-5">
          <h2 className="font-bold text-slate-800">Transactions</h2>
          <p className="mt-1 text-sm text-slate-500">
            Your latest customer deposits, transfers, and payouts
          </p>
        </div>

        {loading ? (
          <div className="flex min-h-[260px] items-center justify-center">
            <div className="text-center">
              <RefreshCcw size={28} className="mx-auto animate-spin text-blue-600" />
              <p className="mt-3 text-sm text-slate-500">Loading transactions...</p>
            </div>
          </div>
        ) : transactions.length === 0 ? (
          <div className="flex min-h-[300px] items-center justify-center px-6">
            <div className="text-center">
              <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-slate-400">
                <HistoryIcon size={30} />
              </div>
              <h3 className="mt-4 font-bold text-slate-900">No transactions yet</h3>
              <p className="mt-1 text-sm text-slate-500">
                Transactions will appear here once processed.
              </p>
            </div>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[1050px]">
              <thead className="bg-slate-50">
                <tr className="text-left">
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wide text-slate-500">
                    Transaction
                  </th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wide text-slate-500">
                    Customer
                  </th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wide text-slate-500">
                    Phone
                  </th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wide text-slate-500">
                    Amount
                  </th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wide text-slate-500">
                    New Balance
                  </th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wide text-slate-500">
                    Status
                  </th>
                  <th className="px-6 py-4 text-xs font-bold uppercase tracking-wide text-slate-500">
                    Date
                  </th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-100">
                {transactions.map((item, index) => (
                  <tr
                    key={item._displayId || index}
                    className="transition hover:bg-slate-50/70"
                  >
                    {/* TRANSACTION */}
                    <td className="px-6 py-5">
                      <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600">
                          <ReceiptText size={18} />
                        </div>
                        <div>
                          <p className="font-semibold text-slate-900">
                            {item._displayId || "-"}
                          </p>
                          <p className="mt-0.5 text-xs text-slate-400">
                            {item._displayType}
                          </p>
                        </div>
                      </div>
                    </td>

                    {/* CUSTOMER */}
                    <td className="px-6 py-5">
                      <div className="flex items-center gap-2">
                        <UserRound size={17} className="text-slate-400" />
                        <span className="font-medium text-slate-800">
                          {item._displayName}
                        </span>
                      </div>
                    </td>

                    {/* PHONE */}
                    <td className="px-6 py-5">
                      <div className="flex items-center gap-2 text-sm text-slate-600">
                        <Phone size={16} className="text-slate-400" />
                        {item._displayPhone}
                      </div>
                    </td>

                    {/* AMOUNT */}
                    <td className="px-6 py-5">
                      <span className="font-bold text-slate-900">
                        $
                        {Number(item._displayAmount || 0).toFixed(2)}
                      </span>
                    </td>

                    {/* NEW BALANCE */}
                    <td className="px-6 py-5">
                      {item._displayBalance !== null ? (
                        <span className="font-semibold text-blue-600">
                          ${Number(item._displayBalance).toFixed(2)}
                        </span>
                      ) : (
                        <span className="text-slate-400">-</span>
                      )}
                    </td>

                    {/* STATUS */}
                    <td className="px-6 py-5">
                      <span
                        className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold capitalize ${
                          item._displayStatus === "success" || item._displayStatus === "claimed"
                            ? "bg-green-50 text-green-700"
                            : item._displayStatus === "pending"
                            ? "bg-amber-50 text-amber-700"
                            : "bg-red-50 text-red-700"
                        }`}
                      >
                        {item._displayStatus === "pending" ? (
                          <Clock size={14} />
                        ) : (
                          <CheckCircle2 size={14} />
                        )}
                        {item._displayStatus}
                      </span>
                    </td>

                    {/* DATE */}
                    <td className="px-6 py-5">
                      <div className="flex items-center gap-2 text-sm text-slate-500">
                        <CalendarDays size={16} className="text-slate-400" />
                        {item._displayDate
                          ? new Date(item._displayDate).toLocaleString()
                          : "-"}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </>
  );
}
