import { useState } from "react";
import {
  X,
  TrendingDown,
  ArrowUpRight,
  PiggyBank,
  UserCog,
  CheckCircle2,
  AlertCircle,
  HelpCircle,
  RefreshCw,
  Coins,
  ShieldCheck,
  Sparkles,
  ArrowRight,
  Calculator,
  Trash2,
} from "lucide-react";
import { reconcileSystemWallet } from "../api/adminApi";

export default function OutflowBreakdownModal({
  isOpen,
  onClose,
  finance,
  onReconcileSuccess,
}) {
  const [activeTab, setActiveTab] = useState("all"); // 'all' | 'savings' | 'agents' | 'reconcile'
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [actionSuccess, setActionSuccess] = useState("");
  const [actionError, setActionError] = useState("");

  if (!isOpen) return null;

  const expenditure = finance?.expenditure || {};
  const totalOutflow = expenditure?.total || 0;
  const agentDisbursed = expenditure?.agent_disbursements || 0;
  const savingsInterest = expenditure?.savings_interest_paid || 0;
  const agentCount = expenditure?.disbursement_count || 0;
  const interestCount = expenditure?.interest_payout_count || 0;
  const bankBalance = finance?.bank_balance || 0;
  const totalIncome = finance?.income?.total || 0;

  const agentItems = expenditure?.agent_topup_items || [];
  const interestItems = expenditure?.interest_payout_items || [];
  const recon = expenditure?.reconciliation || {};

  function formatMoney(amount) {
    return `$${Number(amount || 0).toLocaleString(undefined, {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`;
  }

  function formatDateTime(value) {
    if (!value) return "-";
    const d = new Date(value);
    return isNaN(d.getTime())
      ? String(value)
      : d.toLocaleDateString(undefined, {
          month: "short",
          day: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        });
  }

  async function handleReconciliation(action) {
    try {
      setIsSubmitting(true);
      setActionSuccess("");
      setActionError("");

      const res = await reconcileSystemWallet(action);
      setActionSuccess(res?.message || "Reconciliation completed successfully!");
      if (onReconcileSuccess) {
        await onReconcileSuccess();
      }
    } catch (err) {
      console.error("RECONCILE ERROR:", err);
      setActionError(
        err.response?.data?.detail || "Failed to execute reconciliation action"
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 overflow-y-auto bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="relative w-full max-w-3xl rounded-3xl bg-white shadow-2xl border border-slate-200 overflow-hidden my-8">
        {/* HEADER */}
        <div className="flex items-center justify-between border-b border-slate-100 bg-gradient-to-r from-slate-900 via-slate-800 to-rose-950 px-6 py-5 text-white">
          <div className="flex items-center gap-3">
            <div className="grid h-11 w-11 place-items-center rounded-2xl bg-white/10 text-rose-300">
              <Calculator size={22} />
            </div>
            <div>
              <h2 className="text-xl font-black tracking-tight">
                Bank Outflow & $9.50 Explanation
              </h2>
              <p className="text-xs text-slate-300">
                Detailed breakdown of the {formatMoney(totalOutflow)} total bank expenditure
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="rounded-xl p-2 text-slate-400 hover:bg-white/10 hover:text-white transition"
            aria-label="Close modal"
          >
            <X size={20} />
          </button>
        </div>

        {/* ALERTS */}
        {actionSuccess && (
          <div className="m-5 mb-0 flex items-center gap-2 rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-xs font-semibold text-emerald-800">
            <CheckCircle2 size={16} className="text-emerald-600 shrink-0" />
            <span>{actionSuccess}</span>
          </div>
        )}
        {actionError && (
          <div className="m-5 mb-0 flex items-center gap-2 rounded-2xl border border-rose-200 bg-rose-50 p-4 text-xs font-semibold text-rose-800">
            <AlertCircle size={16} className="text-rose-600 shrink-0" />
            <span>{actionError}</span>
          </div>
        )}

        <div className="p-6 space-y-6 max-h-[75vh] overflow-y-auto">
          {/* =====================================================
              PRIMARY ANSWER CARD (DIRECT CLARIFICATION)
          ===================================================== */}
          <div className="rounded-2xl border-2 border-indigo-200 bg-indigo-50/50 p-5 shadow-sm">
            <div className="flex items-start gap-3">
              <div className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-indigo-600 text-white">
                <HelpCircle size={18} />
              </div>
              <div className="space-y-2">
                <h3 className="text-sm font-bold text-slate-900">
                  Where does the $9.50 come from, and why is Total Outflow {formatMoney(totalOutflow)}?
                </h3>
                <p className="text-xs leading-relaxed text-slate-600">
                  Total Bank Outflow is the combined sum of <span className="font-bold text-slate-900">two separate bank expenditures</span>:
                </p>

                <div className="grid grid-cols-1 gap-2.5 sm:grid-cols-2 pt-1">
                  {/* 1. AGENTS */}
                  <div className="rounded-xl border border-rose-200 bg-white p-3.5 shadow-xs">
                    <div className="flex items-center justify-between">
                      <span className="inline-flex items-center gap-1.5 text-xs font-bold text-rose-700">
                        <UserCog size={15} />
                        1. Agent Float Top-Ups
                      </span>
                      <span className="font-mono text-sm font-black text-rose-700">
                        {formatMoney(agentDisbursed)}
                      </span>
                    </div>
                    <p className="mt-1 text-[11px] text-slate-500">
                      Disbursed to Agent Phon Phe to handle customer counter deposits.
                    </p>
                  </div>

                  {/* 2. SAVINGS INTEREST */}
                  <div className="rounded-xl border border-amber-200 bg-white p-3.5 shadow-xs">
                    <div className="flex items-center justify-between">
                      <span className="inline-flex items-center gap-1.5 text-xs font-bold text-amber-700">
                        <PiggyBank size={15} />
                        2. Savings Interest Paid
                      </span>
                      <span className="font-mono text-sm font-black text-amber-700">
                        {formatMoney(savingsInterest)}
                      </span>
                    </div>
                    <p className="mt-1 text-[11px] text-slate-500">
                      Guaranteed yield paid by KhmerPay Bank to matured customer savings deposits.
                    </p>
                  </div>
                </div>

                {/* FORMULA HIGHLIGHT */}
                <div className="mt-3 flex flex-wrap items-center justify-between rounded-xl bg-slate-900 px-4 py-3 text-white text-xs">
                  <span className="font-medium text-slate-300">Outflow Equation:</span>
                  <div className="font-mono font-bold tracking-wide">
                    <span className="text-rose-300">{formatMoney(agentDisbursed)} (Agents)</span>
                    <span className="mx-1.5 text-slate-400">+</span>
                    <span className="text-amber-300">{formatMoney(savingsInterest)} (Interest)</span>
                    <span className="mx-1.5 text-slate-400">=</span>
                    <span className="text-emerald-400 text-sm font-black">{formatMoney(totalOutflow)} Total Outflow</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* =====================================================
              NAVIGATION TABS
          ===================================================== */}
          <div className="flex items-center gap-2 border-b border-slate-200 pb-3">
            <button
              onClick={() => setActiveTab("all")}
              className={`rounded-xl px-3.5 py-1.5 text-xs font-bold transition ${
                activeTab === "all"
                  ? "bg-slate-900 text-white"
                  : "bg-slate-100 text-slate-600 hover:bg-slate-200"
              }`}
            >
              Full Breakdown ({agentCount + interestCount} txs)
            </button>

            <button
              onClick={() => setActiveTab("savings")}
              className={`rounded-xl px-3.5 py-1.5 text-xs font-bold transition ${
                activeTab === "savings"
                  ? "bg-amber-600 text-white"
                  : "bg-amber-50 text-amber-800 hover:bg-amber-100"
              }`}
            >
              Savings Interest Details ($9.50)
            </button>

            <button
              onClick={() => setActiveTab("agents")}
              className={`rounded-xl px-3.5 py-1.5 text-xs font-bold transition ${
                activeTab === "agents"
                  ? "bg-rose-600 text-white"
                  : "bg-rose-50 text-rose-800 hover:bg-rose-100"
              }`}
            >
              Agent Float Disbursements ($1,500.00)
            </button>

            <button
              onClick={() => setActiveTab("reconcile")}
              className={`rounded-xl px-3.5 py-1.5 text-xs font-bold transition ${
                activeTab === "reconcile"
                  ? "bg-blue-600 text-white"
                  : "bg-blue-50 text-blue-800 hover:bg-blue-100"
              }`}
            >
              Reconcile & Sync Balance
            </button>
          </div>

          {/* =====================================================
              TAB CONTENT: ALL OR SAVINGS INTEREST DETAILS
          ===================================================== */}
          {(activeTab === "all" || activeTab === "savings") && (
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <PiggyBank size={18} className="text-amber-600" />
                  <h4 className="text-xs font-bold uppercase tracking-wider text-slate-700">
                    Customer Savings Interest Payouts ({interestCount} transactions = {formatMoney(savingsInterest)})
                  </h4>
                </div>
                <span className="rounded-full bg-amber-50 px-2.5 py-0.5 text-[11px] font-bold text-amber-700 border border-amber-200">
                  Bank Yield Liability
                </span>
              </div>

              {interestItems.length === 0 ? (
                <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 text-center text-xs text-slate-500">
                  No interest payouts recorded.
                </div>
              ) : (
                <div className="overflow-hidden rounded-2xl border border-amber-200 bg-white">
                  <table className="w-full border-collapse text-left text-xs">
                    <thead className="bg-amber-50/70 border-b border-amber-100 text-slate-600">
                      <tr>
                        <th className="px-4 py-3 font-bold uppercase tracking-wider text-[10px]">Transaction ID</th>
                        <th className="px-4 py-3 font-bold uppercase tracking-wider text-[10px]">Savings ID</th>
                        <th className="px-4 py-3 font-bold uppercase tracking-wider text-[10px]">Reason</th>
                        <th className="px-4 py-3 font-bold uppercase tracking-wider text-[10px] text-right">Amount Paid</th>
                        <th className="px-4 py-3 font-bold uppercase tracking-wider text-[10px]">Date</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium">
                      {interestItems.map((item) => (
                        <tr key={item.transaction_id} className="hover:bg-amber-50/30">
                          <td className="px-4 py-3 font-mono font-bold text-slate-900">
                            {item.transaction_id}
                          </td>
                          <td className="px-4 py-3">
                            <span className="rounded-md bg-indigo-50 px-2 py-0.5 font-mono text-[11px] font-bold text-indigo-700 border border-indigo-200">
                              {item.saving_id || "SAV-DIRECT"}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-slate-600 text-[11px]">
                            {item.description || "Matured savings interest payout"}
                          </td>
                          <td className="px-4 py-3 font-mono font-bold text-amber-700 text-right">
                            -{formatMoney(item.amount)}
                          </td>
                          <td className="px-4 py-3 text-slate-400 text-[11px]">
                            {formatDateTime(item.created_at)}
                          </td>
                        </tr>
                      ))}
                      <tr className="bg-amber-50/50 font-bold border-t border-amber-200">
                        <td colSpan={3} className="px-4 py-2.5 text-slate-700">
                          Total Savings Interest Outflow
                        </td>
                        <td className="px-4 py-2.5 font-mono text-amber-800 text-right font-black">
                          -{formatMoney(savingsInterest)}
                        </td>
                        <td className="px-4 py-2.5"></td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {/* =====================================================
              TAB CONTENT: ALL OR AGENT FLOAT DETAILS
          ===================================================== */}
          {(activeTab === "all" || activeTab === "agents") && (
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <UserCog size={18} className="text-rose-600" />
                  <h4 className="text-xs font-bold uppercase tracking-wider text-slate-700">
                    Agent Float Disbursements ({agentCount} transactions = {formatMoney(agentDisbursed)})
                  </h4>
                </div>
                <span className="rounded-full bg-rose-50 px-2.5 py-0.5 text-[11px] font-bold text-rose-700 border border-rose-200">
                  Branch Liquidity
                </span>
              </div>

              {agentItems.length === 0 ? (
                <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 text-center text-xs text-slate-500">
                  No agent float top ups recorded.
                </div>
              ) : (
                <div className="overflow-hidden rounded-2xl border border-rose-200 bg-white">
                  <table className="w-full border-collapse text-left text-xs">
                    <thead className="bg-rose-50/70 border-b border-rose-100 text-slate-600">
                      <tr>
                        <th className="px-4 py-3 font-bold uppercase tracking-wider text-[10px]">Transaction ID</th>
                        <th className="px-4 py-3 font-bold uppercase tracking-wider text-[10px]">Recipient Agent</th>
                        <th className="px-4 py-3 font-bold uppercase tracking-wider text-[10px]">Description</th>
                        <th className="px-4 py-3 font-bold uppercase tracking-wider text-[10px] text-right">Amount Disbursed</th>
                        <th className="px-4 py-3 font-bold uppercase tracking-wider text-[10px]">Date</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium">
                      {agentItems.map((item) => (
                        <tr key={item.transaction_id} className="hover:bg-rose-50/30">
                          <td className="px-4 py-3 font-mono font-bold text-slate-900">
                            {item.transaction_id}
                          </td>
                          <td className="px-4 py-3 font-bold text-slate-800">
                            {item.agent_name}
                          </td>
                          <td className="px-4 py-3 text-slate-600 text-[11px]">
                            {item.description || "Agent float top up"}
                          </td>
                          <td className="px-4 py-3 font-mono font-bold text-rose-700 text-right">
                            -{formatMoney(item.amount)}
                          </td>
                          <td className="px-4 py-3 text-slate-400 text-[11px]">
                            {formatDateTime(item.created_at)}
                          </td>
                        </tr>
                      ))}
                      <tr className="bg-rose-50/50 font-bold border-t border-rose-200">
                        <td colSpan={3} className="px-4 py-2.5 text-slate-700">
                          Total Agent Float Outflow
                        </td>
                        <td className="px-4 py-2.5 font-mono text-rose-800 text-right font-black">
                          -{formatMoney(agentDisbursed)}
                        </td>
                        <td className="px-4 py-2.5"></td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {/* =====================================================
              RECONCILIATION & BALANCE SYNC PANEL
          ===================================================== */}
          {(activeTab === "all" || activeTab === "reconcile") && (
            <div className="rounded-2xl border border-slate-200 bg-slate-50 p-5 space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <ShieldCheck size={18} className="text-blue-600" />
                  <h4 className="text-xs font-bold uppercase tracking-wider text-slate-800">
                    Treasury Reserve & Balance Reconciliation
                  </h4>
                </div>
                <span className={`rounded-full px-2.5 py-0.5 text-[11px] font-bold ${
                  recon.is_synced
                    ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                    : "bg-blue-50 text-blue-700 border border-blue-200"
                }`}>
                  {recon.is_synced ? "Perfect Balance" : "Active Reserve"}
                </span>
              </div>

              {/* WATERFALL CARDS */}
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
                <div className="rounded-xl border border-slate-200 bg-white p-3">
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Total Funded (Inflow)</p>
                  <p className="mt-1 font-mono text-base font-black text-emerald-600">
                    +{formatMoney(totalIncome)}
                  </p>
                </div>

                <div className="rounded-xl border border-slate-200 bg-white p-3">
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Total Outflow</p>
                  <p className="mt-1 font-mono text-base font-black text-rose-600">
                    -{formatMoney(totalOutflow)}
                  </p>
                </div>

                <div className="rounded-xl border border-slate-200 bg-white p-3">
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Net Flow Position</p>
                  <p className="mt-1 font-mono text-base font-black text-slate-900">
                    {formatMoney(recon.expected_balance ?? totalIncome - totalOutflow)}
                  </p>
                </div>

                <div className="rounded-xl border border-slate-200 bg-white p-3">
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Wallet Reserve</p>
                  <p className="mt-1 font-mono text-base font-black text-blue-600">
                    {formatMoney(bankBalance)}
                  </p>
                </div>
              </div>

              <div className="rounded-xl bg-white border border-slate-200 p-4 text-xs space-y-3">
                <p className="leading-relaxed text-slate-600">
                  <span className="font-bold text-slate-900">Explanation for Admin: </span>
                  You funded <span className="font-semibold text-emerald-700">{formatMoney(totalIncome)}</span> and disbursed <span className="font-semibold text-rose-700">{formatMoney(agentDisbursed)}</span> to agents. This leaves <span className="font-semibold text-blue-700">{formatMoney(bankBalance)}</span> in the System Wallet reserve. The additional <span className="font-semibold text-amber-700">{formatMoney(savingsInterest)}</span> represents savings interest payouts to customers.
                </p>

                <div className="flex flex-wrap items-center gap-3 pt-1">
                  <button
                    onClick={() => handleReconciliation("sync_balance")}
                    disabled={isSubmitting}
                    className="inline-flex items-center gap-1.5 rounded-xl bg-blue-600 px-4 py-2 text-xs font-bold text-white shadow-sm transition hover:bg-blue-700 disabled:opacity-50"
                  >
                    <RefreshCw size={13} className={isSubmitting ? "animate-spin" : ""} />
                    <span>Sync Balance to Net Flow ({formatMoney(totalIncome - totalOutflow)})</span>
                  </button>

                  <button
                    onClick={() => handleReconciliation("clear_test_payouts")}
                    disabled={isSubmitting}
                    className="inline-flex items-center gap-1.5 rounded-xl border border-amber-300 bg-amber-50 px-4 py-2 text-xs font-bold text-amber-800 transition hover:bg-amber-100 disabled:opacity-50"
                  >
                    <Trash2 size={13} />
                    <span>Clear Test Savings Payouts ($9.50)</span>
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* FOOTER */}
        <div className="flex items-center justify-between border-t border-slate-100 bg-slate-50 px-6 py-4">
          <p className="text-xs text-slate-500">
            KhmerPay Treasury • Live Automated Financial Engine
          </p>
          <button
            onClick={onClose}
            className="rounded-xl bg-slate-900 px-5 py-2.5 text-xs font-bold text-white shadow-sm transition hover:bg-slate-800"
          >
            Done / Close
          </button>
        </div>
      </div>
    </div>
  );
}
