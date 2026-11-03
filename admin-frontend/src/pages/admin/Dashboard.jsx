import {
  useEffect,
  useState,
} from "react";

import { Link } from "react-router-dom";

import {
  ArrowDownLeft,
  ArrowRight,
  ArrowUpRight,
  Building2,
  Calendar,
  CheckCircle2,
  Coins,
  History,
  Landmark,
  Percent,
  PiggyBank,
  ReceiptText,
  ShieldCheck,
  TrendingDown,
  TrendingUp,
  UserCog,
  Users,
  Wallet,
} from "lucide-react";

import {
  getAgents,
  getBankFinancialSummary,
  getUsers,
} from "../../api/adminApi";
import OutflowBreakdownModal from "../../components/OutflowBreakdownModal";
import { HelpCircle, Calculator } from "lucide-react";


export default function Dashboard() {
  const [finance, setFinance] = useState({
    bank_balance: 0,
    currency: "USD",
    income: {
      total: 0,
      system_funding: 0,
      funding_count: 0,
    },
    expenditure: {
      total: 0,
      agent_disbursements: 0,
      disbursement_count: 0,
      savings_interest_paid: 0,
      interest_payout_count: 0,
    },
    net_flow: 0,
    savings: {
      active_savings_volume: 0,
      active_savings_count: 0,
      projected_interest_liability: 0,
      completed_savings_volume: 0,
      completed_savings_count: 0,
      unique_savers_count: 0,
      reserve_coverage_ratio: 100,
      recent_savings: [],
    },
    recent_activities: [],
  });

  const [users, setUsers] = useState([]);
  const [agents, setAgents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showOutflowModal, setShowOutflowModal] = useState(false);


  useEffect(() => {
    loadDashboard();
  }, []);


  async function loadDashboard() {
    try {
      setLoading(true);

      const [summaryRes, usersRes, agentsRes] = await Promise.all([
        getBankFinancialSummary().catch((err) => {
          console.error("FAILED TO LOAD BANK FINANCIAL SUMMARY:", err);
          return null;
        }),
        getUsers().catch((err) => {
          console.error("FAILED TO LOAD USERS:", err);
          return null;
        }),
        getAgents().catch((err) => {
          console.error("FAILED TO LOAD AGENTS:", err);
          return null;
        }),
      ]);

      if (summaryRes?.data) {
        setFinance(summaryRes.data);
      }

      setUsers(usersRes?.data || []);
      setAgents(agentsRes?.data || []);

    } catch (error) {
      console.error("DASHBOARD ERROR:", error);
    } finally {
      setLoading(false);
    }
  }


  // =====================================================
  // FINANCIAL METRICS & HELPERS
  // =====================================================

  function formatMoney(amount) {
    return `$${Number(amount || 0).toLocaleString(undefined, {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`;
  }

  function formatDate(value) {
    if (!value) return "-";
    const d = new Date(value);
    return isNaN(d.getTime())
      ? String(value)
      : d.toLocaleDateString(undefined, {
          year: "numeric",
          month: "short",
          day: "numeric",
        });
  }

  function formatDateTime(value) {
    if (!value) return "-";
    const d = new Date(value);
    return isNaN(d.getTime())
      ? String(value)
      : d.toLocaleString(undefined, {
          month: "short",
          day: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        });
  }

  function getKycLabel(status) {
    switch (status) {
      case "approved":
        return "Approved";
      case "rejected":
        return "Rejected";
      case "pending_review":
        return "Pending Review";
      case "nid_front_uploaded":
      case "nid_uploaded":
      case "nid_confirmed":
        return "In Progress";
      case "not_submitted":
        return "Not Submitted";
      default:
        return status || "-";
    }
  }

  function getKycClass(status) {
    if (status === "approved") {
      return "bg-green-50 text-green-700";
    }
    if (status === "rejected") {
      return "bg-red-50 text-red-700";
    }
    if (status === "pending_review") {
      return "bg-amber-50 text-amber-700";
    }
    return "bg-slate-100 text-slate-600";
  }

  const verifiedUsers = users.filter((u) => u.kyc_status === "approved").length;
  const activeAgentsCount = agents.filter((a) => a.is_active !== false).length;

  const totalIncome = finance?.income?.total || 0;
  const totalExpenditure = finance?.expenditure?.total || 0;
  const bankBalance = finance?.bank_balance || 0;
  const netFlow = finance?.net_flow || 0;

  const savingsStats = finance?.savings || {};
  const activeSavingsVolume = savingsStats.active_savings_volume || 0;
  const projectedInterestLiability = savingsStats.projected_interest_liability || 0;
  const totalMaturityObligations = activeSavingsVolume + projectedInterestLiability;
  const reserveCoverageRatio = savingsStats.reserve_coverage_ratio || 100;

  const recentSavings = savingsStats.recent_savings || [];
  const recentActivities = finance?.recent_activities || [];


  return (
    <div className="space-y-7 pb-12">
      {/* =====================================================
          HEADER
      ===================================================== */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2.5">
            <h1 className="text-3xl font-black tracking-tight text-slate-900">
              Bank Financial Dashboard
            </h1>
            <span className="inline-flex items-center gap-1.5 rounded-full border border-blue-200 bg-blue-50 px-2.5 py-0.5 text-xs font-bold text-blue-700">
              <span className="h-1.5 w-1.5 rounded-full bg-blue-600 animate-pulse" />
              Treasury Active
            </span>
          </div>

          <p className="mt-1 text-sm text-slate-500">
            KhmerPay financial control, bank reserve liquidity, operational revenue & savings management
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2.5">
          <Link
            to="/admin/wallet"
            className="inline-flex items-center gap-2 rounded-xl bg-blue-600 px-4 py-2.5 text-xs font-bold text-white shadow-sm transition hover:bg-blue-700 active:scale-95"
          >
            <Landmark size={15} />
            <span>Fund Bank Wallet</span>
          </Link>

          <Link
            to="/admin/savings"
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-xs font-bold text-slate-700 shadow-sm transition hover:bg-slate-50 active:scale-95"
          >
            <PiggyBank size={15} className="text-indigo-600" />
            <span>Savings & Rates</span>
          </Link>
        </div>
      </div>


      {loading ? (
        <div className="flex min-h-[360px] items-center justify-center rounded-3xl border border-slate-200 bg-white shadow-sm">
          <div className="text-center">
            <div className="mx-auto h-9 w-9 animate-spin rounded-full border-4 border-slate-200 border-t-blue-600" />
            <p className="mt-4 text-sm font-semibold text-slate-500">
              Calculating bank financial position & savings reserves...
            </p>
          </div>
        </div>
      ) : (
        <>
          {/* =====================================================
              PRIMARY FINANCIAL METRICS (4 CORE CARDS)
              - Bank Balance (Available Reserve)
              - Total Bank Income (Inflows)
              - Total Bank Expenditure (Outflows)
              - Customer Savings Deposits (AUM Custody)
          ===================================================== */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {/* 1. BANK BALANCE (LIQUID RESERVE) */}
            <div className="relative overflow-hidden rounded-3xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
              <div className="flex items-start justify-between">
                <div className="grid h-12 w-12 place-items-center rounded-2xl bg-blue-50 text-blue-600">
                  <Landmark size={23} />
                </div>
                <span className="rounded-full bg-blue-50 px-2.5 py-0.5 text-[11px] font-bold text-blue-700">
                  Bank Reserve
                </span>
              </div>
              <div className="mt-4">
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                  Available Bank Balance
                </p>
                <p className="mt-1 text-2xl font-black text-slate-900 lg:text-3xl">
                  {formatMoney(bankBalance)}
                </p>
                <p className="mt-1 text-xs text-slate-500">
                  Liquid funds in KhmerPay System Wallet
                </p>
              </div>
            </div>

            {/* 2. BANK INCOME (INFLOW) */}
            <div className="relative overflow-hidden rounded-3xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
              <div className="flex items-start justify-between">
                <div className="grid h-12 w-12 place-items-center rounded-2xl bg-emerald-50 text-emerald-600">
                  <ArrowDownLeft size={23} />
                </div>
                <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-0.5 text-[11px] font-bold text-emerald-700">
                  <TrendingUp size={12} />
                  Total Income
                </span>
              </div>
              <div className="mt-4">
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                  Bank Total Inflow
                </p>
                <p className="mt-1 text-2xl font-black text-emerald-700 lg:text-3xl">
                  {formatMoney(totalIncome)}
                </p>
                <p className="mt-1 text-xs text-slate-500">
                  {finance?.income?.funding_count || 0} capital funding injections
                </p>
              </div>
            </div>

            {/* 3. BANK EXPENDITURE (OUTFLOW) */}
            <div className="relative overflow-hidden rounded-3xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
              <div className="flex items-start justify-between">
                <div className="grid h-12 w-12 place-items-center rounded-2xl bg-rose-50 text-rose-600">
                  <ArrowUpRight size={23} />
                </div>
                <button
                  type="button"
                  onClick={() => setShowOutflowModal(true)}
                  className="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2.5 py-0.5 text-[11px] font-bold text-rose-700 transition hover:bg-rose-100 cursor-pointer"
                >
                  <TrendingDown size={12} />
                  Total Expenditure
                </button>
              </div>
              <div className="mt-4">
                <div className="flex items-center justify-between">
                  <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                    Bank Total Outflow
                  </p>
                  <button
                    type="button"
                    onClick={() => setShowOutflowModal(true)}
                    className="inline-flex items-center gap-1 text-[11px] font-bold text-rose-600 hover:text-rose-700 underline underline-offset-2 cursor-pointer"
                  >
                    <HelpCircle size={13} />
                    <span>Why $9.50?</span>
                  </button>
                </div>
                <p className="mt-1 text-2xl font-black text-rose-700 lg:text-3xl">
                  {formatMoney(totalExpenditure)}
                </p>

                {/* BREAKDOWN PILLS */}
                <div className="mt-2.5 flex flex-wrap gap-1.5 text-[11px]">
                  <span className="inline-flex items-center gap-1 rounded-md bg-rose-50 px-2 py-0.5 font-bold text-rose-700 border border-rose-100">
                    <UserCog size={11} />
                    Agent Float: {formatMoney(finance?.expenditure?.agent_disbursements || 0)}
                  </span>
                  <span className="inline-flex items-center gap-1 rounded-md bg-amber-50 px-2 py-0.5 font-bold text-amber-700 border border-amber-100">
                    <PiggyBank size={11} />
                    Savings Interest: {formatMoney(finance?.expenditure?.savings_interest_paid || 0)}
                  </span>
                </div>

                <p className="mt-2 text-[11px] leading-tight text-slate-500">
                  Total of $1,500.00 agent float + $9.50 customer savings interest
                </p>
              </div>
            </div>

            {/* 4. CUSTOMER SAVINGS DEPOSITS (AUM CUSTODY) */}
            <div className="relative overflow-hidden rounded-3xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
              <div className="flex items-start justify-between">
                <div className="grid h-12 w-12 place-items-center rounded-2xl bg-indigo-50 text-indigo-600">
                  <PiggyBank size={23} />
                </div>
                <span className="rounded-full bg-indigo-50 px-2.5 py-0.5 text-[11px] font-bold text-indigo-700">
                  Customer Savings
                </span>
              </div>
              <div className="mt-4">
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                  Savings Under Custody
                </p>
                <p className="mt-1 text-2xl font-black text-indigo-900 lg:text-3xl">
                  {formatMoney(activeSavingsVolume)}
                </p>
                <p className="mt-1 text-xs text-slate-500">
                  {savingsStats.active_savings_count || 0} active accounts • {formatMoney(projectedInterestLiability)} committed interest
                </p>
              </div>
            </div>
          </div>


          {/* =====================================================
              TREASURY OVERVIEW & FINANCIAL POSITION BANNER
          ===================================================== */}
          <div className="overflow-hidden rounded-3xl border border-slate-200 bg-gradient-to-br from-slate-900 via-slate-900 to-blue-950 p-6 text-white shadow-xl shadow-slate-900/10 md:p-8">
            <div className="flex flex-col justify-between gap-6 lg:flex-row lg:items-center">
              <div>
                <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-blue-300">
                  <ShieldCheck size={16} className="text-emerald-400" />
                  Bank Treasury & Solvency Health
                </div>

                <div className="mt-2 flex flex-wrap items-baseline gap-3">
                  <h2 className="text-3xl font-black tracking-tight text-white md:text-4xl">
                    Net Reserve Position: {netFlow >= 0 ? "+" : ""}{formatMoney(netFlow)}
                  </h2>
                  <span className={`rounded-full px-3 py-1 text-xs font-extrabold ${
                    netFlow >= 0 ? "bg-emerald-500/20 text-emerald-300 border border-emerald-500/30" : "bg-rose-500/20 text-rose-300 border border-rose-500/30"
                  }`}>
                    {netFlow >= 0 ? "Positive Net Position" : "Deficit Warning"}
                  </span>
                </div>

                <p className="mt-2 max-w-2xl text-xs leading-relaxed text-slate-300 md:text-sm">
                  The bank maintains an available liquid reserve of <span className="font-bold text-white">{formatMoney(bankBalance)}</span>.
                  {projectedInterestLiability > 0 ? (
                    <> This reserve covers <span className="font-bold text-emerald-400">{reserveCoverageRatio}%</span> of all future customer savings interest obligations.</>
                  ) : (
                    <> Customer savings interest liabilities are fully supported and backed by bank reserves.</>
                  )}
                </p>
              </div>

              {/* Flow Formula Strip */}
                <div className="mt-4 flex flex-wrap items-center gap-2 rounded-2xl bg-white/10 p-3 text-xs backdrop-blur-md border border-white/10">
                  <span className="font-bold text-slate-300 uppercase tracking-wider text-[10px]">Equation:</span>
                  <span className="font-mono font-bold text-emerald-300">+{formatMoney(totalIncome)} (Funded)</span>
                  <span className="text-slate-400 font-bold">-</span>
                  <span className="font-mono font-bold text-rose-300">-{formatMoney(finance?.expenditure?.agent_disbursements || 0)} (Agent Float)</span>
                  <span className="text-slate-400 font-bold">-</span>
                  <span className="font-mono font-bold text-amber-300">-{formatMoney(finance?.expenditure?.savings_interest_paid || 0)} (Savings Interest)</span>
                  <span className="text-slate-400 font-bold">=</span>
                  <span className="font-mono font-black text-white">{netFlow >= 0 ? "+" : ""}{formatMoney(netFlow)} Net Flow</span>
                  <button
                    type="button"
                    onClick={() => setShowOutflowModal(true)}
                    className="ml-auto inline-flex items-center gap-1 rounded-lg bg-rose-500/30 hover:bg-rose-500/40 px-2.5 py-1 text-[11px] font-bold text-rose-200 border border-rose-400/30 transition cursor-pointer"
                  >
                    <Calculator size={13} />
                    <span>Inspect $9.50 & Outflow</span>
                  </button>
                </div>

                {/* Breakdown Grid Inside Banner */}
              <div className="grid grid-cols-2 gap-3 rounded-2xl bg-white/10 p-4 backdrop-blur-md border border-white/10 sm:grid-cols-2 lg:min-w-[320px]">
                <div className="p-2">
                  <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                    System Funding (Income)
                  </p>
                  <p className="mt-1 font-mono text-lg font-black text-emerald-300">
                    +{formatMoney(finance?.income?.system_funding || 0)}
                  </p>
                </div>

                <div className="p-2">
                  <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                    Agent Float Disbursed
                  </p>
                  <p className="mt-1 font-mono text-lg font-black text-rose-300">
                    -{formatMoney(finance?.expenditure?.agent_disbursements || 0)}
                  </p>
                </div>

                <div className="p-2 border-t border-white/10">
                  <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                    Savings Interest Paid
                  </p>
                  <p className="mt-1 font-mono text-lg font-black text-amber-300">
                    -{formatMoney(finance?.expenditure?.savings_interest_paid || 0)}
                  </p>
                </div>

                <div className="p-2 border-t border-white/10">
                  <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                    Interest Liability (Accrued)
                  </p>
                  <p className="mt-1 font-mono text-lg font-black text-blue-300">
                    {formatMoney(projectedInterestLiability)}
                  </p>
                </div>
              </div>
            </div>
          </div>


          {/* =====================================================
              CUSTOMER SAVINGS & LIABILITIES HUB (FINANCE ENGINE)
          ===================================================== */}
          <div className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm">
            <div className="flex flex-col gap-3 border-b border-slate-100 p-5 sm:flex-row sm:items-center sm:justify-between sm:px-6">
              <div>
                <div className="flex items-center gap-2">
                  <PiggyBank className="text-indigo-600" size={22} />
                  <h2 className="text-lg font-black text-slate-900 md:text-xl">
                    Customer Savings & Time Deposits
                  </h2>
                </div>
                <p className="mt-0.5 text-xs text-slate-500">
                  Customer funds locked in high-yield savings, committed interest liabilities & maturity schedules
                </p>
              </div>

              <div className="flex items-center gap-3">
                <Link
                  to="/admin/savings"
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-indigo-600 hover:text-indigo-700"
                >
                  <span>Manage Interest Rates & Simulators</span>
                  <ArrowRight size={15} />
                </Link>
              </div>
            </div>

            {/* Savings Key Financial Metrics */}
            <div className="grid grid-cols-2 divide-y divide-slate-100 border-b border-slate-100 sm:grid-cols-4 sm:divide-x sm:divide-y-0">
              <div className="p-4 sm:p-5">
                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  Active Principal Held
                </p>
                <p className="mt-1 text-xl font-black text-slate-900">
                  {formatMoney(activeSavingsVolume)}
                </p>
                <p className="mt-0.5 text-xs text-slate-500">
                  {savingsStats.active_savings_count || 0} active savings deposits
                </p>
              </div>

              <div className="p-4 sm:p-5">
                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  Committed Interest Liability
                </p>
                <p className="mt-1 text-xl font-black text-indigo-600">
                  {formatMoney(projectedInterestLiability)}
                </p>
                <p className="mt-0.5 text-xs text-slate-500">
                  Guaranteed return to savers
                </p>
              </div>

              <div className="p-4 sm:p-5">
                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  Total Maturity Obligations
                </p>
                <p className="mt-1 text-xl font-black text-slate-900">
                  {formatMoney(totalMaturityObligations)}
                </p>
                <p className="mt-0.5 text-xs text-slate-500">
                  Principal + interest due
                </p>
              </div>

              <div className="p-4 sm:p-5">
                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                  Active Savers
                </p>
                <p className="mt-1 text-xl font-black text-slate-900">
                  {savingsStats.unique_savers_count || 0} Customers
                </p>
                <p className="mt-0.5 text-xs text-slate-500">
                  {savingsStats.completed_savings_count || 0} matured deposits
                </p>
              </div>
            </div>

            {/* Savings Table or Empty State */}
            {recentSavings.length === 0 ? (
              <div className="flex min-h-[200px] flex-col items-center justify-center p-8 text-center">
                <div className="grid h-12 w-12 place-items-center rounded-2xl bg-indigo-50 text-indigo-600">
                  <PiggyBank size={24} />
                </div>
                <h3 className="mt-3 text-sm font-bold text-slate-900">
                  Ready for Customer Savings Deposits
                </h3>
                <p className="mt-1 max-w-md text-xs leading-relaxed text-slate-500">
                  Customer savings hub is active. When users lock funds into high-yield savings terms configured by the bank,
                  the principal custody, accrued interest liability, and maturity payouts will appear here in real time.
                </p>
                <Link
                  to="/admin/savings"
                  className="mt-4 inline-flex items-center gap-1.5 rounded-xl bg-indigo-50 px-4 py-2 text-xs font-bold text-indigo-700 transition hover:bg-indigo-100"
                >
                  <span>Configure Interest Rates</span>
                  <ArrowRight size={14} />
                </Link>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full border-collapse">
                  <thead className="bg-slate-50">
                    <tr className="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                      <th className="whitespace-nowrap px-6 py-4">Customer Saver</th>
                      <th className="whitespace-nowrap px-6 py-4">Principal Deposited</th>
                      <th className="whitespace-nowrap px-6 py-4">Term & Rate</th>
                      <th className="whitespace-nowrap px-6 py-4">Projected Interest</th>
                      <th className="whitespace-nowrap px-6 py-4">Total Payout</th>
                      <th className="whitespace-nowrap px-6 py-4">Maturity Date</th>
                      <th className="whitespace-nowrap px-6 py-4">Status</th>
                    </tr>
                  </thead>

                  <tbody className="divide-y divide-slate-100">
                    {recentSavings.map((s) => (
                      <tr key={s.id || s.saving_id} className="transition hover:bg-slate-50">
                        <td className="whitespace-nowrap px-6 py-4">
                          <p className="font-semibold text-slate-900">{s.user_name}</p>
                          <p className="text-xs font-mono text-slate-400">{s.phone_number || s.saving_id}</p>
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 font-bold text-slate-900">
                          {formatMoney(s.principal)}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 text-xs font-medium text-slate-700">
                          <span className="rounded-md bg-slate-100 px-2 py-1 font-semibold text-slate-800">
                            {s.term}
                          </span>
                          <span className="ml-2 text-indigo-600 font-bold">{s.rate}%</span>
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 font-semibold text-emerald-600">
                          +{formatMoney(s.interest_amount)}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 font-bold text-slate-900">
                          {formatMoney(s.total_payout)}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 text-xs text-slate-500">
                          {formatDate(s.maturity_date)}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4">
                          <span
                            className={
                              s.status === "active"
                                ? "inline-flex rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700"
                                : "inline-flex rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700"
                            }
                          >
                            {s.status === "active" ? "Active (Locked)" : "Matured / Paid"}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>


          {/* =====================================================
              RECENT FINANCIAL ACTIVITIES (INCOME & EXPENDITURE LEDGER)
          ===================================================== */}
          <div className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm">
            <div className="flex items-center justify-between border-b border-slate-100 px-6 py-5">
              <div>
                <div className="flex items-center gap-2">
                  <History size={20} className="text-blue-600" />
                  <h2 className="text-lg font-black text-slate-900 md:text-xl">
                    Recent Bank Financial Movements
                  </h2>
                </div>
                <p className="mt-0.5 text-xs text-slate-500">
                  Record of capital funding injections (Income) and disbursements / interest payouts (Expenditure)
                </p>
              </div>

              <Link
                to="/admin/wallet"
                className="inline-flex items-center gap-1.5 text-xs font-bold text-blue-600 hover:text-blue-700"
              >
                <span>Full Wallet History</span>
                <ArrowRight size={15} />
              </Link>
            </div>

            {recentActivities.length === 0 ? (
              <div className="flex min-h-[160px] items-center justify-center text-xs font-semibold text-slate-500">
                No recent financial activities recorded
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full border-collapse">
                  <thead className="bg-slate-50">
                    <tr className="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                      <th className="whitespace-nowrap px-6 py-4">Transaction</th>
                      <th className="whitespace-nowrap px-6 py-4">Category</th>
                      <th className="whitespace-nowrap px-6 py-4">Impact / Amount</th>
                      <th className="whitespace-nowrap px-6 py-4">Description</th>
                      <th className="whitespace-nowrap px-6 py-4">Date & Time</th>
                    </tr>
                  </thead>

                  <tbody className="divide-y divide-slate-100">
                    {recentActivities.slice(0, 7).map((item) => (
                      <tr key={item.id || item.transaction_id} className="transition hover:bg-slate-50">
                        <td className="whitespace-nowrap px-6 py-4">
                          <p className="font-mono text-xs font-bold text-slate-900">
                            {item.transaction_id}
                          </p>
                          <p className="text-xs text-slate-400">{item.label}</p>
                        </td>

                        <td className="whitespace-nowrap px-6 py-4">
                          <span
                            className={
                              item.direction === "inflow"
                                ? "inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-bold text-emerald-700 border border-emerald-200"
                                : item.type === "system_interest_payout"
                                ? "inline-flex items-center gap-1 rounded-full bg-amber-50 px-2.5 py-1 text-xs font-bold text-amber-700 border border-amber-200"
                                : "inline-flex items-center gap-1 rounded-full bg-rose-50 px-2.5 py-1 text-xs font-bold text-rose-700 border border-rose-200"
                            }
                          >
                            {item.direction === "inflow" ? (
                              <>
                                <ArrowDownLeft size={13} />
                                <span>Capital Inflow</span>
                              </>
                            ) : item.type === "system_interest_payout" ? (
                              <>
                                <PiggyBank size={13} />
                                <span>Savings Interest Paid</span>
                              </>
                            ) : (
                              <>
                                <ArrowUpRight size={13} />
                                <span>Agent Float Outflow</span>
                              </>
                            )}
                          </span>
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 font-mono font-black text-sm">
                          <span className={item.direction === "inflow" ? "text-emerald-700" : item.type === "system_interest_payout" ? "text-amber-700" : "text-rose-700"}>
                            {item.direction === "inflow" ? "+" : "-"}{formatMoney(item.amount)}
                          </span>
                        </td>

                        <td className="max-w-xs truncate px-6 py-4 text-xs text-slate-600">
                          {item.description || "-"}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 text-xs text-slate-500">
                          {formatDateTime(item.created_at)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>


          {/* =====================================================
              OPERATIONS: AGENTS (WITHOUT BALANCE) & RECENT CUSTOMERS
              (No "balance agent" - Pure operational oversight)
          ===================================================== */}
          <div className="grid grid-cols-1 gap-7 lg:grid-cols-2">
            {/* AGENTS OPERATIONAL CONTROL (NO AGENT BALANCE SHOWN) */}
            <div className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm">
              <div className="flex items-center justify-between border-b border-slate-100 px-6 py-5">
                <div>
                  <div className="flex items-center gap-2">
                    <UserCog size={20} className="text-blue-600" />
                    <h2 className="text-base font-black text-slate-900 md:text-lg">
                      Agents Operations ({agents.length})
                    </h2>
                  </div>
                  <p className="mt-0.5 text-xs text-slate-500">
                    KhmerPay counter branches & operations (operational view)
                  </p>
                </div>

                <Link
                  to="/admin/agents"
                  className="inline-flex items-center gap-1 text-xs font-bold text-blue-600 hover:text-blue-700"
                >
                  <span>Manage</span>
                  <ArrowRight size={14} />
                </Link>
              </div>

              {agents.length === 0 ? (
                <div className="flex min-h-[160px] items-center justify-center text-xs text-slate-500">
                  No agents registered yet
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full border-collapse">
                    <thead className="bg-slate-50">
                      <tr className="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        <th className="whitespace-nowrap px-5 py-3.5">Agent</th>
                        <th className="whitespace-nowrap px-5 py-3.5">Phone</th>
                        <th className="whitespace-nowrap px-5 py-3.5">Branch</th>
                        <th className="whitespace-nowrap px-5 py-3.5">Status</th>
                      </tr>
                    </thead>

                    <tbody className="divide-y divide-slate-100">
                      {agents.slice(0, 5).map((agent) => (
                        <tr key={agent.id || agent._id} className="transition hover:bg-slate-50">
                          <td className="whitespace-nowrap px-5 py-3.5">
                            <div className="flex items-center gap-2.5">
                              <div className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-blue-50 font-bold text-blue-700 text-xs">
                                {agent.first_name?.charAt(0).toUpperCase() || "A"}
                              </div>
                              <div>
                                <p className="font-semibold text-slate-900 text-xs sm:text-sm">
                                  {agent.first_name} {agent.last_name}
                                </p>
                                <p className="text-[11px] font-mono text-slate-400">
                                  {agent.agent_code || "AGT-COUNTER"}
                                </p>
                              </div>
                            </div>
                          </td>

                          <td className="whitespace-nowrap px-5 py-3.5 text-xs font-mono text-slate-600">
                            {agent.phone_number}
                          </td>

                          <td className="whitespace-nowrap px-5 py-3.5 text-xs text-slate-600">
                            {agent.branch_name || "Main Counter"}
                          </td>

                          <td className="whitespace-nowrap px-5 py-3.5">
                            <span
                              className={
                                agent.is_active
                                  ? "inline-flex rounded-full bg-emerald-50 px-2.5 py-0.5 text-[11px] font-bold text-emerald-700"
                                  : "inline-flex rounded-full bg-rose-50 px-2.5 py-0.5 text-[11px] font-bold text-rose-700"
                              }
                            >
                              {agent.is_active ? "Active" : "Disabled"}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            {/* RECENT CUSTOMERS (NO CUSTOMER BALANCE SHOWN) */}
            <div className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm">
              <div className="flex items-center justify-between border-b border-slate-100 px-6 py-5">
                <div>
                  <div className="flex items-center gap-2">
                    <Users size={20} className="text-blue-600" />
                    <h2 className="text-base font-black text-slate-900 md:text-lg">
                      Recent Customers ({users.length})
                    </h2>
                  </div>
                  <p className="mt-0.5 text-xs text-slate-500">
                    Latest registered customers & verification status
                  </p>
                </div>

                <Link
                  to="/admin/users"
                  className="inline-flex items-center gap-1 text-xs font-bold text-blue-600 hover:text-blue-700"
                >
                  <span>All Users</span>
                  <ArrowRight size={14} />
                </Link>
              </div>

              {users.length === 0 ? (
                <div className="flex min-h-[160px] items-center justify-center text-xs text-slate-500">
                  No customers registered yet
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full border-collapse">
                    <thead className="bg-slate-50">
                      <tr className="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        <th className="whitespace-nowrap px-5 py-3.5">Customer</th>
                        <th className="whitespace-nowrap px-5 py-3.5">Phone</th>
                        <th className="whitespace-nowrap px-5 py-3.5">KYC Tier</th>
                        <th className="whitespace-nowrap px-5 py-3.5">Status</th>
                      </tr>
                    </thead>

                    <tbody className="divide-y divide-slate-100">
                      {users.slice(0, 5).map((user) => (
                        <tr key={user.id || user._id} className="transition hover:bg-slate-50">
                          <td className="whitespace-nowrap px-5 py-3.5">
                            <div className="flex items-center gap-2.5">
                              <div className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-slate-100 font-bold text-slate-700 text-xs">
                                {user.first_name?.charAt(0).toUpperCase() || "U"}
                              </div>
                              <div>
                                <p className="font-semibold text-slate-900 text-xs sm:text-sm">
                                  {user.first_name} {user.last_name}
                                </p>
                                <p className="text-[11px] text-slate-400">Customer</p>
                              </div>
                            </div>
                          </td>

                          <td className="whitespace-nowrap px-5 py-3.5 text-xs font-mono text-slate-600">
                            {user.phone_number}
                          </td>

                          <td className="whitespace-nowrap px-5 py-3.5">
                            <span
                              className={`inline-flex rounded-full px-2.5 py-0.5 text-[11px] font-bold ${getKycClass(
                                user.kyc_status
                              )}`}
                            >
                              {getKycLabel(user.kyc_status)}
                            </span>
                          </td>

                          <td className="whitespace-nowrap px-5 py-3.5">
                            <span
                              className={
                                user.is_active
                                  ? "inline-flex rounded-full bg-emerald-50 px-2.5 py-0.5 text-[11px] font-bold text-emerald-700"
                                  : "inline-flex rounded-full bg-rose-50 px-2.5 py-0.5 text-[11px] font-bold text-rose-700"
                              }
                            >
                              {user.is_active ? "Active" : "Disabled"}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </>
      )}
      {/* =====================================================
          OUTFLOW BREAKDOWN & RECONCILIATION MODAL
      ===================================================== */}
      <OutflowBreakdownModal
        isOpen={showOutflowModal}
        onClose={() => setShowOutflowModal(false)}
        finance={finance}
        onReconcileSuccess={loadDashboard}
      />
    </div>
  );
}
