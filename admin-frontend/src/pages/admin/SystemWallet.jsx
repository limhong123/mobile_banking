import { useEffect, useState } from "react";
import {
  ArrowDownLeft,
  ArrowDownToLine,
  ArrowRight,
  ArrowUpFromLine,
  ArrowUpRight,
  Calculator,
  CheckCircle2,
  Coins,
  HelpCircle,
  History,
  Landmark,
  PiggyBank,
  Plus,
  RefreshCw,
  ShieldCheck,
  TrendingDown,
  TrendingUp,
  UserCog,
  Wallet,
  X,
} from "lucide-react";

import {
  fundSystemWallet,
  getBankFinancialSummary,
  getSystemWallet,
  getSystemWalletHistory,
} from "../../api/adminApi";
import OutflowBreakdownModal from "../../components/OutflowBreakdownModal";

export default function SystemWallet() {
  const [wallet, setWallet] = useState({
    balance: 0,
    currency: "USD",
  });

  const [finance, setFinance] = useState({
    bank_balance: 0,
    currency: "USD",
    income: { total: 0, system_funding: 0, funding_count: 0 },
    expenditure: {
      total: 0,
      agent_disbursements: 0,
      disbursement_count: 0,
      savings_interest_paid: 0,
      interest_payout_count: 0,
      agent_topup_items: [],
      interest_payout_items: [],
      breakdown: [],
      reconciliation: {},
    },
    net_flow: 0,
    savings: {},
    recent_activities: [],
  });

  const [history, setHistory] = useState([]);
  const [historyFilter, setHistoryFilter] = useState("all"); // 'all' | 'inflow' | 'agents' | 'savings'
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Modals
  const [showFundModal, setShowFundModal] = useState(false);
  const [showOutflowModal, setShowOutflowModal] = useState(false);
  const [amount, setAmount] = useState("");
  const [description, setDescription] = useState("");
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    loadWalletData();
  }, []);

  async function loadWalletData() {
    try {
      setLoading(true);
      setError("");

      const [walletRes, historyRes, summaryRes] = await Promise.all([
        getSystemWallet().catch((err) => {
          console.error("GET WALLET ERROR:", err);
          return null;
        }),
        getSystemWalletHistory().catch((err) => {
          console.error("GET HISTORY ERROR:", err);
          return null;
        }),
        getBankFinancialSummary().catch((err) => {
          console.error("GET FINANCIAL SUMMARY ERROR:", err);
          return null;
        }),
      ]);

      if (walletRes?.data) {
        setWallet(walletRes.data);
      }
      if (historyRes?.data) {
        setHistory(historyRes.data);
      }
      if (summaryRes?.data) {
        setFinance(summaryRes.data);
      }
    } catch (err) {
      console.error("SYSTEM WALLET ERROR:", err);
      const detail = err.response?.data?.detail;
      setError(typeof detail === "string" ? detail : "Unable to load System Wallet");
    } finally {
      setLoading(false);
    }
  }

  // =====================================================
  // MODAL HANDLERS
  // =====================================================
  function openFundModal() {
    setAmount("");
    setDescription("");
    setShowFundModal(true);
  }

  function closeFundModal() {
    if (submitting) return;
    setShowFundModal(false);
    setAmount("");
    setDescription("");
  }

  async function handleFund(e) {
    e.preventDefault();
    const value = Number(amount);

    if (!Number.isFinite(value) || value <= 0) {
      alert("Please enter a valid amount");
      return;
    }
    if (value > 1000000) {
      alert("Maximum amount is $1,000,000");
      return;
    }

    const confirmed = window.confirm(`Add $${value.toFixed(2)} to System Wallet?`);
    if (!confirmed) return;

    try {
      setSubmitting(true);
      await fundSystemWallet(value, description.trim() || "Admin system funding");
      setShowFundModal(false);
      setAmount("");
      setDescription("");
      await loadWalletData();
      alert("System Wallet funded successfully");
    } catch (err) {
      console.error("FUND ERROR:", err);
      const detail = err.response?.data?.detail;
      alert(typeof detail === "string" ? detail : "Unable to fund System Wallet");
    } finally {
      setSubmitting(false);
    }
  }

  // =====================================================
  // HELPERS
  // =====================================================
  function formatMoney(val) {
    return `$${Number(val || 0).toLocaleString(undefined, {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`;
  }

  function formatDate(val) {
    if (!val) return "-";
    const d = new Date(val);
    return isNaN(d.getTime())
      ? String(val)
      : d.toLocaleDateString(undefined, {
          month: "short",
          day: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        });
  }

  // Filtered transactions
  const filteredHistory = history.filter((item) => {
    if (historyFilter === "inflow") return item.type === "system_funding" || item.direction === "inflow";
    if (historyFilter === "agents") return item.type === "agent_topup";
    if (historyFilter === "savings") return item.type === "system_interest_payout";
    return true;
  });

  const totalInflow = finance?.income?.total || 0;
  const totalOutflow = finance?.expenditure?.total || 0;
  const agentDisbursed = finance?.expenditure?.agent_disbursements || 0;
  const savingsInterestPaid = finance?.expenditure?.savings_interest_paid || 0;
  const bankBalance = wallet?.balance ?? finance?.bank_balance ?? 0;

  return (
    <>
      {/* =====================================================
          HEADER
      ===================================================== */}
      <div className="mb-7 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2.5">
            <h1 className="text-3xl font-black tracking-tight text-slate-900">
              System Wallet & Bank Treasury
            </h1>
            <span className="inline-flex items-center gap-1.5 rounded-full border border-blue-200 bg-blue-50 px-2.5 py-0.5 text-xs font-bold text-blue-700">
              <span className="h-1.5 w-1.5 rounded-full bg-blue-600 animate-pulse" />
              Main Reserve
            </span>
          </div>
          <p className="mt-1 text-sm text-slate-500">
            KhmerPay system capital balance, agent liquidity disbursements & savings interest ledger
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2.5">
          <button
            type="button"
            onClick={() => setShowOutflowModal(true)}
            className="inline-flex items-center gap-2 rounded-xl border border-rose-200 bg-rose-50 px-4 py-2.5 text-xs font-bold text-rose-700 shadow-xs transition hover:bg-rose-100 active:scale-95 cursor-pointer"
          >
            <Calculator size={15} />
            <span>Explain $9.50 & Outflow</span>
          </button>

          <button
            type="button"
            onClick={openFundModal}
            className="inline-flex items-center gap-2 rounded-xl bg-blue-600 px-5 py-2.5 text-xs font-bold text-white shadow-sm transition hover:bg-blue-700 active:scale-95 cursor-pointer"
          >
            <Plus size={16} />
            <span>Add Money to Wallet</span>
          </button>
        </div>
      </div>

      {/* ERROR BANNER */}
      {error && (
        <div className="mb-6 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-xs font-semibold text-rose-700">
          {error}
        </div>
      )}

      {loading ? (
        <div className="flex min-h-[320px] items-center justify-center rounded-3xl border border-slate-200 bg-white shadow-sm">
          <div className="text-center">
            <div className="mx-auto h-8 w-8 animate-spin rounded-full border-4 border-slate-200 border-t-blue-600" />
            <p className="mt-4 text-xs font-semibold text-slate-500">
              Loading System Wallet & Treasury ledger...
            </p>
          </div>
        </div>
      ) : (
        <>
          {/* =====================================================
              PRIMARY FINANCIAL METRIC CARDS (3 CORE METRICS)
          ===================================================== */}
          <div className="mb-7 grid grid-cols-1 gap-4 sm:grid-cols-3">
            {/* 1. AVAILABLE SYSTEM BALANCE */}
            <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-blue-600 via-blue-600 to-indigo-700 p-6 text-white shadow-lg shadow-blue-600/10">
              <div className="flex items-start justify-between">
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/15">
                  <Wallet size={24} />
                </div>
                <span className="rounded-full bg-white/20 px-2.5 py-0.5 text-[11px] font-bold text-white backdrop-blur-sm">
                  Active Reserve
                </span>
              </div>
              <div className="mt-4">
                <p className="text-xs font-medium text-blue-100 uppercase tracking-wider">
                  Available System Balance
                </p>
                <h2 className="mt-1 text-3xl font-black tracking-tight lg:text-4xl">
                  {formatMoney(bankBalance)}
                </h2>
                <p className="mt-1 text-xs text-blue-100">
                  {wallet.currency || "USD"} • KhmerPay Treasury Reserve
                </p>
              </div>
            </div>

            {/* 2. TOTAL CAPITAL INFLOW */}
            <div className="relative overflow-hidden rounded-3xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
              <div className="flex items-start justify-between">
                <div className="grid h-12 w-12 place-items-center rounded-2xl bg-emerald-50 text-emerald-600">
                  <ArrowDownLeft size={24} />
                </div>
                <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-0.5 text-[11px] font-bold text-emerald-700">
                  <TrendingUp size={12} />
                  Total Funded
                </span>
              </div>
              <div className="mt-4">
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                  Total Capital Inflow
                </p>
                <p className="mt-1 text-3xl font-black text-emerald-700">
                  +{formatMoney(totalInflow)}
                </p>
                <p className="mt-1 text-xs text-slate-500">
                  {finance?.income?.funding_count || 1} admin capital injection(s)
                </p>
              </div>
            </div>

            {/* 3. TOTAL BANK OUTFLOW */}
            <div className="relative overflow-hidden rounded-3xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
              <div className="flex items-start justify-between">
                <div className="grid h-12 w-12 place-items-center rounded-2xl bg-rose-50 text-rose-600">
                  <ArrowUpRight size={24} />
                </div>
                <button
                  type="button"
                  onClick={() => setShowOutflowModal(true)}
                  className="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2.5 py-0.5 text-[11px] font-bold text-rose-700 hover:bg-rose-100 transition cursor-pointer"
                >
                  <HelpCircle size={12} />
                  Why {formatMoney(totalOutflow)}?
                </button>
              </div>
              <div className="mt-4">
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                  Total Bank Outflow
                </p>
                <p className="mt-1 text-3xl font-black text-rose-700">
                  -{formatMoney(totalOutflow)}
                </p>

                {/* BREAKDOWN PILLS */}
                <div className="mt-2.5 flex flex-wrap gap-1.5 text-[11px]">
                  <span className="inline-flex items-center gap-1 rounded-md bg-rose-50 px-2 py-0.5 font-bold text-rose-700 border border-rose-100">
                    <UserCog size={11} />
                    Agent Float: {formatMoney(agentDisbursed)}
                  </span>
                  <span className="inline-flex items-center gap-1 rounded-md bg-amber-50 px-2 py-0.5 font-bold text-amber-700 border border-amber-100">
                    <PiggyBank size={11} />
                    Savings Interest: {formatMoney(savingsInterestPaid)}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* =====================================================
              EDUCATIONAL / RECONCILIATION CALLOUT BANNER
              (Answers: Why is Outflow $1509.50 and where is $9.50 from?)
          ===================================================== */}
          <div className="mb-7 overflow-hidden rounded-3xl border-2 border-indigo-200 bg-gradient-to-br from-indigo-50/80 via-white to-blue-50/60 p-6 shadow-sm">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
              <div className="space-y-1.5">
                <div className="flex items-center gap-2">
                  <div className="grid h-7 w-7 place-items-center rounded-lg bg-indigo-600 text-white">
                    <Calculator size={15} />
                  </div>
                  <h3 className="text-sm font-black text-slate-900">
                    Treasury Flow Math & $9.50 Breakdown
                  </h3>
                  <span className="rounded-full bg-indigo-100 px-2 py-0.5 text-[10px] font-bold text-indigo-800">
                    Transparent Ledger
                  </span>
                </div>

                <p className="max-w-2xl text-xs leading-relaxed text-slate-600">
                  You funded <span className="font-bold text-slate-900">{formatMoney(totalInflow)}</span> into the System Wallet. From this, <span className="font-bold text-rose-700">{formatMoney(agentDisbursed)}</span> was transferred to Agent Phon Phe (leaving <span className="font-bold text-blue-700">{formatMoney(bankBalance)}</span> available). An additional <span className="font-bold text-amber-700">{formatMoney(savingsInterestPaid)}</span> was paid out to customer savings accounts upon deposit maturity, making <span className="font-bold text-rose-700">Total Outflow {formatMoney(totalOutflow)}</span>.
                </p>
              </div>

              <div className="flex flex-wrap items-center gap-2">
                <button
                  type="button"
                  onClick={() => setShowOutflowModal(true)}
                  className="inline-flex items-center gap-1.5 rounded-xl bg-indigo-600 px-4 py-2.5 text-xs font-bold text-white shadow-sm transition hover:bg-indigo-700 active:scale-95 cursor-pointer"
                >
                  <span>View All Payouts & Math</span>
                  <ArrowRight size={14} />
                </button>
              </div>
            </div>

            {/* FLOW EQUATION STRIP */}
            <div className="mt-4 flex flex-wrap items-center gap-2 rounded-2xl bg-white border border-indigo-100 p-3 text-xs">
              <span className="font-bold text-slate-500 uppercase tracking-wider text-[10px]">
                Equation:
              </span>
              <span className="font-mono font-bold text-emerald-700">
                +{formatMoney(totalInflow)} (Funded)
              </span>
              <span className="text-slate-400 font-bold">-</span>
              <span className="font-mono font-bold text-rose-700">
                {formatMoney(agentDisbursed)} (Agent Top-Up)
              </span>
              <span className="text-slate-400 font-bold">-</span>
              <span className="font-mono font-bold text-amber-700">
                {formatMoney(savingsInterestPaid)} (Customer Savings Interest: $7.50 + $2.00)
              </span>
              <span className="text-slate-400 font-bold">=</span>
              <span className="font-mono font-black text-indigo-900">
                {formatMoney(totalInflow - totalOutflow)} Net Reserve
              </span>
            </div>
          </div>

          {/* =====================================================
              OPERATIONAL FLOW (STEPS 1 - 3)
          ===================================================== */}
          <div className="mb-7 grid grid-cols-1 gap-4 lg:grid-cols-3">
            {/* STEP 1 */}
            <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600">
                <Plus size={20} />
              </div>
              <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                Step 1
              </p>
              <h3 className="mt-1 text-sm font-bold text-slate-900">
                Admin Capital Funding
              </h3>
              <p className="mt-1 text-xs leading-5 text-slate-500">
                Inject capital directly into the KhmerPay System Wallet treasury to back bank operations.
              </p>
            </div>

            {/* STEP 2 */}
            <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-amber-50 text-amber-600">
                <ArrowUpFromLine size={20} />
              </div>
              <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                Step 2
              </p>
              <h3 className="mt-1 text-sm font-bold text-slate-900">
                Agent Float Top-Up
              </h3>
              <p className="mt-1 text-xs leading-5 text-slate-500">
                Transfer liquidity from System Wallet to counter agents so agents can process user deposits.
              </p>
            </div>

            {/* STEP 3 */}
            <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600">
                <PiggyBank size={20} />
              </div>
              <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                Step 3
              </p>
              <h3 className="mt-1 text-sm font-bold text-slate-900">
                Customer Savings Yield
              </h3>
              <p className="mt-1 text-xs leading-5 text-slate-500">
                Guaranteed yield is debited from System Wallet and credited to users upon savings maturity.
              </p>
            </div>
          </div>

          {/* =====================================================
              WALLET HISTORY & FULL MOVEMENT LEDGER
          ===================================================== */}
          <div className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm">
            <div className="flex flex-col gap-4 border-b border-slate-100 p-6 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <div className="flex items-center gap-2">
                  <History size={20} className="text-blue-600" />
                  <h2 className="text-lg font-black text-slate-900">
                    System Wallet Movement Ledger
                  </h2>
                </div>
                <p className="mt-0.5 text-xs text-slate-500">
                  Comprehensive audit trail of capital injections, agent disbursements, and customer interest payouts
                </p>
              </div>

              {/* FILTER TABS */}
              <div className="flex flex-wrap items-center gap-1.5 rounded-xl bg-slate-100 p-1 text-xs font-bold">
                <button
                  onClick={() => setHistoryFilter("all")}
                  className={`rounded-lg px-3 py-1.5 transition cursor-pointer ${
                    historyFilter === "all"
                      ? "bg-white text-slate-900 shadow-xs"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  All ({history.length})
                </button>
                <button
                  onClick={() => setHistoryFilter("inflow")}
                  className={`rounded-lg px-3 py-1.5 transition cursor-pointer ${
                    historyFilter === "inflow"
                      ? "bg-white text-emerald-700 shadow-xs"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  Inflow (+${totalInflow.toLocaleString()})
                </button>
                <button
                  onClick={() => setHistoryFilter("agents")}
                  className={`rounded-lg px-3 py-1.5 transition cursor-pointer ${
                    historyFilter === "agents"
                      ? "bg-white text-rose-700 shadow-xs"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  Agent Float (-${agentDisbursed.toLocaleString()})
                </button>
                <button
                  onClick={() => setHistoryFilter("savings")}
                  className={`rounded-lg px-3 py-1.5 transition cursor-pointer ${
                    historyFilter === "savings"
                      ? "bg-white text-amber-700 shadow-xs"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  Savings Interest (-${savingsInterestPaid.toLocaleString()})
                </button>
              </div>
            </div>

            {filteredHistory.length === 0 ? (
              <div className="flex min-h-[200px] flex-col items-center justify-center p-8 text-center">
                <div className="grid h-12 w-12 place-items-center rounded-2xl bg-slate-100 text-slate-400">
                  <Wallet size={24} />
                </div>
                <h3 className="mt-3 text-sm font-bold text-slate-800">
                  No movements found
                </h3>
                <p className="mt-1 text-xs text-slate-500">
                  No records matching the selected filter criteria.
                </p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full border-collapse">
                  <thead className="bg-slate-50 border-b border-slate-100">
                    <tr className="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                      <th className="whitespace-nowrap px-6 py-4">Transaction</th>
                      <th className="whitespace-nowrap px-6 py-4">Category</th>
                      <th className="whitespace-nowrap px-6 py-4">Reference / Target</th>
                      <th className="whitespace-nowrap px-6 py-4">Amount</th>
                      <th className="whitespace-nowrap px-6 py-4">Description</th>
                      <th className="whitespace-nowrap px-6 py-4">Date & Time</th>
                    </tr>
                  </thead>

                  <tbody className="divide-y divide-slate-100">
                    {filteredHistory.map((item) => (
                      <tr
                        key={item.id || item.transaction_id}
                        className="transition hover:bg-slate-50"
                      >
                        <td className="whitespace-nowrap px-6 py-4">
                          <p className="font-mono text-xs font-bold text-slate-900">
                            {item.transaction_id}
                          </p>
                          <p className="text-[11px] text-slate-400">
                            {item.label || item.type}
                          </p>
                        </td>

                        <td className="whitespace-nowrap px-6 py-4">
                          {item.type === "system_funding" ? (
                            <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-0.5 text-[11px] font-bold text-emerald-700 border border-emerald-200">
                              <ArrowDownLeft size={11} />
                              Capital Inflow
                            </span>
                          ) : item.type === "agent_topup" ? (
                            <span className="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2.5 py-0.5 text-[11px] font-bold text-rose-700 border border-rose-200">
                              <ArrowUpRight size={11} />
                              Agent Float Outflow
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2.5 py-0.5 text-[11px] font-bold text-amber-700 border border-amber-200">
                              <PiggyBank size={11} />
                              Savings Interest Outflow
                            </span>
                          )}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4">
                          {item.agent_name ? (
                            <div className="flex items-center gap-1.5">
                              <UserCog size={14} className="text-slate-400" />
                              <span className="font-semibold text-slate-800 text-xs">
                                {item.agent_name}
                              </span>
                            </div>
                          ) : item.saving_id ? (
                            <div className="flex items-center gap-1.5">
                              <PiggyBank size={14} className="text-amber-500" />
                              <span className="rounded-md bg-indigo-50 px-2 py-0.5 font-mono text-[11px] font-bold text-indigo-700 border border-indigo-200">
                                {item.saving_id}
                              </span>
                            </div>
                          ) : (
                            <span className="text-xs text-slate-400">KhmerPay Treasury</span>
                          )}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 font-mono font-black text-sm">
                          {item.direction === "inflow" || item.type === "system_funding" ? (
                            <span className="text-emerald-700">
                              +{formatMoney(item.amount)}
                            </span>
                          ) : item.type === "system_interest_payout" ? (
                            <span className="text-amber-700">
                              -{formatMoney(item.amount)}
                            </span>
                          ) : (
                            <span className="text-rose-700">
                              -{formatMoney(item.amount)}
                            </span>
                          )}
                        </td>

                        <td className="max-w-xs truncate px-6 py-4 text-xs text-slate-600">
                          {item.description || "-"}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 text-xs text-slate-500">
                          {formatDate(item.created_at)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </>
      )}

      {/* ================================================
          ADD MONEY MODAL
      ================================================= */}
      {showFundModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-3xl bg-white p-7 shadow-2xl border border-slate-100">
            <div className="mb-6 flex items-start justify-between gap-5">
              <div>
                <h2 className="text-2xl font-black text-slate-900">
                  Add Capital to Treasury
                </h2>
                <p className="mt-1 text-xs text-slate-500">
                  Inject funds into KhmerPay System Wallet
                </p>
              </div>

              <button
                type="button"
                onClick={closeFundModal}
                disabled={submitting}
                className="rounded-xl bg-slate-100 p-2 text-slate-600 transition hover:bg-slate-200 disabled:opacity-50"
              >
                <X size={20} />
              </button>
            </div>

            {/* CURRENT BALANCE */}
            <div className="mb-5 rounded-2xl bg-blue-50 p-4 border border-blue-100">
              <p className="text-[11px] font-bold uppercase tracking-wider text-blue-600">
                Current Reserve Balance
              </p>
              <p className="mt-1 text-2xl font-black text-blue-700">
                {formatMoney(bankBalance)}
              </p>
            </div>

            <form onSubmit={handleFund}>
              <label className="mb-2 block text-xs font-bold uppercase tracking-wider text-slate-700">
                Deposit Amount ($ USD)
              </label>

              <div className="flex items-center rounded-2xl border border-slate-200 px-4 transition focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">
                <span className="font-bold text-slate-400">$</span>
                <input
                  type="number"
                  step="0.01"
                  min="0.01"
                  max="1000000"
                  placeholder="0.00"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="w-full bg-transparent px-3 py-3 text-base font-bold text-slate-900 outline-none"
                  required
                />
              </div>

              <label className="mt-4 mb-2 block text-xs font-bold uppercase tracking-wider text-slate-700">
                Funding Note / Reason
              </label>
              <input
                type="text"
                placeholder="e.g. Treasury Capital Injection"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full rounded-2xl border border-slate-200 px-4 py-3 text-xs font-medium text-slate-900 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
              />

              <div className="mt-6 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={closeFundModal}
                  disabled={submitting}
                  className="rounded-xl border border-slate-200 px-4 py-2.5 text-xs font-bold text-slate-700 transition hover:bg-slate-50 disabled:opacity-50"
                >
                  Cancel
                </button>

                <button
                  type="submit"
                  disabled={submitting}
                  className="rounded-xl bg-blue-600 px-5 py-2.5 text-xs font-bold text-white shadow-sm transition hover:bg-blue-700 disabled:opacity-50"
                >
                  {submitting ? "Processing..." : "Confirm Funding"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ================================================
          OUTFLOW BREAKDOWN & EXPLANATION MODAL
      ================================================= */}
      <OutflowBreakdownModal
        isOpen={showOutflowModal}
        onClose={() => setShowOutflowModal(false)}
        finance={finance}
        onReconcileSuccess={loadWalletData}
      />
    </>
  );
}
