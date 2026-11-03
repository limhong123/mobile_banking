import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  AlertCircle,
  AlertTriangle,
  ArrowRight,
  Banknote,
  Building2,
  Check,
  CheckCircle2,
  Clock,
  Copy,
  Eye,
  EyeOff,
  History,
  ReceiptText,
  RefreshCw,
  Search,
  ShieldCheck,
  TrendingUp,
  UserCheck,
  Wallet,
  X,
  XCircle,
} from "lucide-react";

import {
  getAgentDashboard,
  getAgentProfile,
  searchCustomer,
} from "../../api/agentApi";

export default function AgentDashboard() {
  const navigate = useNavigate();

  const [dashboardData, setDashboardData] = useState(null);
  const [profileData, setProfileData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState("");

  // UI States
  const [showBalance, setShowBalance] = useState(true);
  const [copiedId, setCopiedId] = useState(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");

  // Quick Customer Lookup States
  const [lookupPhone, setLookupPhone] = useState("");
  const [lookupCustomerData, setLookupCustomerData] = useState(null);
  const [lookupSearching, setLookupSearching] = useState(false);
  const [lookupError, setLookupError] = useState("");

  // =====================================================
  // INITIAL LOAD
  // =====================================================
  useEffect(() => {
    loadData();
  }, []);

  async function loadData(isRefresh = false) {
    try {
      setError("");
      if (isRefresh) {
        setRefreshing(true);
      } else {
        setLoading(true);
      }

      const [dashRes, profRes] = await Promise.allSettled([
        getAgentDashboard(),
        getAgentProfile(),
      ]);

      if (dashRes.status === "fulfilled") {
        setDashboardData(dashRes.value?.data || {});
      } else {
        console.error("Dashboard error:", dashRes.reason);
        const detail = dashRes.reason?.response?.data?.detail;
        setError(
          typeof detail === "string"
            ? detail
            : detail?.message || "Unable to load dashboard data."
        );
      }

      if (profRes.status === "fulfilled") {
        setProfileData(profRes.value?.data || {});
      }
    } catch (err) {
      console.error("Agent dashboard error:", err);
      setError("An unexpected error occurred while fetching dashboard data.");
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  // =====================================================
  // QUICK CUSTOMER LOOKUP
  // =====================================================
  async function handleQuickLookup(e) {
    if (e) e.preventDefault();
    const phone = lookupPhone.trim();
    if (!phone) {
      setLookupError("Please enter a customer phone number.");
      return;
    }

    try {
      setLookupSearching(true);
      setLookupError("");
      setLookupCustomerData(null);

      const res = await searchCustomer(phone);
      if (res?.data) {
        setLookupCustomerData(res.data);
      } else {
        setLookupError("No customer found registered with this phone number.");
      }
    } catch (err) {
      console.error("Quick lookup error:", err);
      const detail = err.response?.data?.detail;
      setLookupError(
        typeof detail === "string"
          ? detail
          : detail?.message || "Customer not found."
      );
    } finally {
      setLookupSearching(false);
    }
  }

  function handleResetLookup() {
    setLookupPhone("");
    setLookupCustomerData(null);
    setLookupError("");
  }

  // =====================================================
  // DERIVED DATA & METRICS
  // =====================================================
  const walletBalance = Number(
    dashboardData?.wallet_balance ??
      dashboardData?.balance ??
      profileData?.balance ??
      0
  );

  const currency = dashboardData?.currency || profileData?.currency || "USD";
  const isWalletFrozen = Boolean(dashboardData?.wallet_frozen);

  const rawDailyLimit =
    dashboardData?.daily_transaction_limit ??
    profileData?.daily_transaction_limit ??
    null;

  const hasLimit = rawDailyLimit != null && Number(rawDailyLimit) > 0;
  const dailyLimit = hasLimit ? Number(rawDailyLimit) : null;

  const todayAmount = Number(
    dashboardData?.today_transaction_amount ??
      profileData?.today_transaction_amount ??
      0
  );

  const remainingLimit = hasLimit
    ? Number(
        dashboardData?.remaining_daily_limit ??
          profileData?.remaining_daily_limit ??
          Math.max(0, dailyLimit - todayAmount)
      )
    : null;

  const limitUsedPercent =
    hasLimit && dailyLimit > 0
      ? Math.min(100, Math.round((todayAmount / dailyLimit) * 100))
      : 0;

  const totalTransactions = Number(dashboardData?.total_transactions ?? 0);
  const totalDeposits = Number(
    dashboardData?.total_deposit_amount ??
      dashboardData?.total_deposit ??
      0
  );

  // Local storage user fallback for display
  const localUser = useMemo(() => {
    try {
      return JSON.parse(localStorage.getItem("user") || "{}");
    } catch {
      return {};
    }
  }, []);

  const agentName =
    profileData?.first_name || profileData?.last_name
      ? `${profileData.first_name || ""} ${profileData.last_name || ""}`.trim()
      : localUser?.first_name || localUser?.name || "Agent";

  const agentCode =
    profileData?.agent_code ||
    localUser?.agent_code ||
    `AGT-${(profileData?.id || localUser?._id || "0000").slice(-4).toUpperCase()}`;

  const branchName =
    profileData?.branch_name ||
    localUser?.branch_name ||
    "KhmerPay Counter";

  // Filtered transactions
  const filteredTransactions = useMemo(() => {
    const list = Array.isArray(dashboardData?.recent_transactions)
      ? dashboardData.recent_transactions
      : [];

    return list.filter((item) => {
      const q = searchQuery.toLowerCase().trim();
      const matchesSearch =
        !q ||
        (item.customer_name && item.customer_name.toLowerCase().includes(q)) ||
        (item.customer_phone && item.customer_phone.toLowerCase().includes(q)) ||
        (item.transaction_id && item.transaction_id.toLowerCase().includes(q));

      const status = (item.status || "").toLowerCase();
      const matchesStatus =
        statusFilter === "all" ||
        (statusFilter === "success" &&
          (status === "success" || status === "completed")) ||
        (statusFilter === "pending" && status === "pending") ||
        (statusFilter === "failed" &&
          (status === "failed" || status === "rejected"));

      return matchesSearch && matchesStatus;
    });
  }, [dashboardData?.recent_transactions, searchQuery, statusFilter]);

  // Copy to clipboard helper
  function handleCopy(text) {
    if (!text) return;
    navigator.clipboard?.writeText(text);
    setCopiedId(text);
    setTimeout(() => {
      setCopiedId(null);
    }, 2000);
  }

  return (
    <div className="space-y-7 pb-10">
      {/* =====================================================
          TOP HEADER
      ===================================================== */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex items-center gap-2.5">
            <h1 className="text-2xl font-black tracking-tight text-slate-900 md:text-3xl">
              Hello, {agentName}!
            </h1>
            <span className="inline-flex items-center gap-1.5 rounded-full border border-emerald-200 bg-emerald-50 px-2.5 py-0.5 text-xs font-bold text-emerald-700">
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Counter Active
            </span>
          </div>

          <div className="mt-1 flex flex-wrap items-center gap-3 text-xs font-medium text-slate-500 md:text-sm">
            <span className="flex items-center gap-1 text-slate-600 font-semibold">
              <ShieldCheck size={15} className="text-[#1249AD]" />
              Agent ID: <span className="font-mono text-slate-900">{agentCode}</span>
            </span>
            <span className="text-slate-300">•</span>
            <span className="flex items-center gap-1 text-slate-600">
              <Building2 size={15} className="text-slate-400" />
              {branchName}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2.5">
          <button
            type="button"
            disabled={refreshing || loading}
            onClick={() => loadData(true)}
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3.5 py-2 text-xs font-bold text-slate-700 shadow-sm transition hover:bg-slate-50 hover:text-slate-900 active:scale-95 disabled:cursor-not-allowed disabled:opacity-50 md:text-sm"
            title="Refresh balance and transactions"
          >
            <RefreshCw
              size={16}
              className={`text-slate-500 ${refreshing ? "animate-spin text-[#1249AD]" : ""}`}
            />
            <span>{refreshing ? "Updating..." : "Refresh"}</span>
          </button>
        </div>
      </div>

      {/* =====================================================
          ERROR BANNER
      ===================================================== */}
      {error && (
        <div className="flex items-center gap-3 rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-medium text-red-800 shadow-sm">
          <AlertCircle size={20} className="shrink-0 text-red-600" />
          <div className="flex-1">{error}</div>
          <button
            type="button"
            onClick={() => loadData(true)}
            className="rounded-lg bg-red-100 px-3 py-1 text-xs font-bold text-red-700 hover:bg-red-200"
          >
            Retry
          </button>
        </div>
      )}

      {/* =====================================================
          LOADING SKELETON OR CONTENT
      ===================================================== */}
      {loading ? (
        <div className="space-y-6">
          <div className="h-56 animate-pulse rounded-3xl bg-slate-200/80" />
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div className="h-28 animate-pulse rounded-2xl bg-slate-200/80" />
            <div className="h-28 animate-pulse rounded-2xl bg-slate-200/80" />
            <div className="h-28 animate-pulse rounded-2xl bg-slate-200/80" />
            <div className="h-28 animate-pulse rounded-2xl bg-slate-200/80" />
          </div>
          <div className="h-80 animate-pulse rounded-3xl bg-slate-200/80" />
        </div>
      ) : (
        <>
          {/* =====================================================
              HERO: AGENT WALLET FLOAT & COUNTER QUOTA
          ===================================================== */}
          <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-[#0c2e6b] via-[#1249AD] to-[#1e5ecc] p-6 text-white shadow-xl shadow-blue-900/15 md:p-8">
            {/* Background decorative patterns */}
            <div className="pointer-events-none absolute -right-16 -top-16 h-64 w-64 rounded-full bg-blue-400/20 blur-3xl" />
            <div className="pointer-events-none absolute -bottom-16 -left-16 h-64 w-64 rounded-full bg-cyan-400/20 blur-3xl" />
            <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(#ffffff_1px,transparent_1px)] [background-size:24px_24px] opacity-10" />

            <div className="relative z-10 flex flex-col justify-between gap-6 lg:flex-row lg:items-center">
              {/* Left Column: Big Balance Display */}
              <div className="space-y-3">
                <div className="flex flex-wrap items-center gap-3">
                  <div className="flex items-center gap-2 rounded-full bg-white/15 px-3 py-1 text-xs font-bold uppercase tracking-wider text-blue-100 backdrop-blur-md">
                    <Wallet size={14} className="text-cyan-300" />
                    Agent Float Balance
                  </div>

                  {isWalletFrozen ? (
                    <span className="inline-flex items-center gap-1 rounded-full bg-red-500/80 px-2.5 py-0.5 text-xs font-bold text-white backdrop-blur-md">
                      <XCircle size={13} />
                      Wallet Frozen
                    </span>
                  ) : walletBalance < 100 ? (
                    <span className="inline-flex items-center gap-1 rounded-full bg-amber-500/30 px-2.5 py-0.5 text-xs font-bold text-amber-200 backdrop-blur-md border border-amber-400/30">
                      <AlertTriangle size={13} />
                      Low Float Warning
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 rounded-full bg-emerald-500/30 px-2.5 py-0.5 text-xs font-bold text-emerald-200 backdrop-blur-md border border-emerald-400/30">
                      <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-ping" />
                      Active & Ready
                    </span>
                  )}

                  <button
                    type="button"
                    onClick={() => setShowBalance(!showBalance)}
                    className="flex items-center gap-1.5 rounded-full bg-white/10 px-2.5 py-1 text-xs font-medium text-blue-100 backdrop-blur-md transition hover:bg-white/20 active:scale-95"
                    title={showBalance ? "Hide balance from view" : "Show balance"}
                  >
                    {showBalance ? (
                      <>
                        <EyeOff size={13} />
                        <span>Hide</span>
                      </>
                    ) : (
                      <>
                        <Eye size={13} />
                        <span>Show</span>
                      </>
                    )}
                  </button>
                </div>

                {/* Big Balance Number */}
                <div className="flex items-baseline gap-3 pt-1">
                  <div className="font-sans text-4xl font-black tracking-tight text-white md:text-5xl lg:text-6xl drop-shadow-sm">
                    {showBalance ? (
                      <>
                        <span className="text-blue-200 text-3xl md:text-4xl lg:text-5xl mr-1 font-bold">
                          $
                        </span>
                        {walletBalance.toLocaleString(undefined, {
                          minimumFractionDigits: 2,
                          maximumFractionDigits: 2,
                        })}
                      </>
                    ) : (
                      <span className="tracking-widest text-blue-100 font-mono text-3xl md:text-4xl">
                        ••••••••••
                      </span>
                    )}
                  </div>

                  <span className="rounded-md bg-blue-500/30 px-2 py-0.5 text-xs font-extrabold uppercase tracking-wide text-cyan-200 border border-blue-400/20">
                    {currency}
                  </span>
                </div>

                <p className="max-w-xl text-xs leading-relaxed text-blue-100/90 md:text-sm">
                  Total available fund allocated to your counter float. Use this balance
                  to execute cash deposits and customer operations.
                </p>
              </div>

              {/* Right Column: Counter Operational Quota Summary */}
              <div className="flex flex-col justify-between rounded-2xl bg-white/10 p-5 backdrop-blur-md border border-white/15 lg:min-w-[300px]">
                <div className="flex items-center justify-between pb-3 border-b border-white/15">
                  <span className="text-xs font-bold uppercase tracking-wider text-blue-200">
                    Daily Counter Quota
                  </span>
                  <span className="rounded-full bg-white/20 px-2.5 py-0.5 text-xs font-bold text-white">
                    {hasLimit ? `${limitUsedPercent}% Used` : "Unlimited"}
                  </span>
                </div>

                <div className="py-3.5 space-y-2.5">
                  <div className="flex justify-between items-baseline text-xs text-blue-100">
                    <span className="text-blue-200">Processed Today:</span>
                    <span className="font-extrabold text-white text-sm">
                      ${todayAmount.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                    </span>
                  </div>

                  <div className="flex justify-between items-baseline text-xs text-blue-100">
                    <span className="text-blue-200">Remaining Quota:</span>
                    <span className="font-extrabold text-cyan-200 text-sm">
                      {hasLimit
                        ? `$${remainingLimit.toLocaleString(undefined, { minimumFractionDigits: 2 })}`
                        : "No Limit"}
                    </span>
                  </div>

                  {/* Quota Progress Bar */}
                  <div className="mt-1">
                    <div className="h-2 w-full overflow-hidden rounded-full bg-white/20">
                      <div
                        className="h-full rounded-full bg-cyan-300 transition-all duration-500"
                        style={{ width: `${hasLimit ? limitUsedPercent : 100}%` }}
                      />
                    </div>
                  </div>
                </div>

                <div className="pt-3 border-t border-white/15 flex items-center justify-between text-xs text-blue-100">
                  <span className="flex items-center gap-1.5">
                    <span className="h-2 w-2 rounded-full bg-emerald-400" />
                    Counter Ready
                  </span>
                  <span className="font-mono text-cyan-200 font-semibold">{agentCode}</span>
                </div>
              </div>
            </div>

            {/* Bottom info strip inside balance card */}
            <div className="relative z-10 mt-6 pt-4 border-t border-white/15 flex flex-wrap items-center justify-between gap-3 text-xs text-blue-200 font-medium">
              <div className="flex items-center gap-2">
                <span className="font-bold text-white">Counter Branch:</span>
                <span>{branchName}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="font-bold text-white">Float Status:</span>
                <span className={isWalletFrozen ? "text-red-300" : "text-emerald-300"}>
                  {isWalletFrozen ? "Frozen / Restricted" : "Active & Operational"}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <span className="font-bold text-white">Daily Deposit Cap:</span>
                <span>{hasLimit ? `$${dailyLimit.toLocaleString()}` : "Unlimited"}</span>
              </div>
            </div>
          </div>

          {/* =====================================================
              METRICS STAT CARDS
          ===================================================== */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {/* Today's Deposits */}
            <div className="group relative overflow-hidden rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:border-blue-300 hover:shadow-md">
              <div className="flex items-start justify-between">
                <div className="grid h-12 w-12 place-items-center rounded-xl bg-blue-50 text-[#1249AD]">
                  <TrendingUp size={22} />
                </div>
                <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[11px] font-bold text-[#1249AD]">
                  Today
                </span>
              </div>
              <div className="mt-4">
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                  Today's Deposits
                </p>
                <p className="mt-1 text-2xl font-black text-slate-900">
                  ${todayAmount.toLocaleString(undefined, {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2,
                  })}
                </p>
                <p className="mt-1 text-xs text-slate-500">
                  Processed in the current 24h window
                </p>
              </div>
            </div>

            {/* Remaining Limit */}
            <div className="group relative overflow-hidden rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:border-emerald-300 hover:shadow-md">
              <div className="flex items-start justify-between">
                <div className="grid h-12 w-12 place-items-center rounded-xl bg-emerald-50 text-emerald-600">
                  <ShieldCheck size={22} />
                </div>
                <span className="rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-bold text-emerald-700">
                  {hasLimit ? "Available" : "No Limit"}
                </span>
              </div>
              <div className="mt-4">
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                  Daily Limit Left
                </p>
                <p className="mt-1 text-2xl font-black text-slate-900">
                  {hasLimit
                    ? `$${remainingLimit.toLocaleString(undefined, {
                        minimumFractionDigits: 2,
                        maximumFractionDigits: 2,
                      })}`
                    : "Unlimited"}
                </p>
                <p className="mt-1 text-xs text-slate-500">
                  {hasLimit
                    ? `Out of $${dailyLimit.toLocaleString()} cap`
                    : "No daily limit for deposits"}
                </p>
              </div>
            </div>

            {/* Total Lifetime Deposits */}
            <div className="group relative overflow-hidden rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:border-indigo-300 hover:shadow-md">
              <div className="flex items-start justify-between">
                <div className="grid h-12 w-12 place-items-center rounded-xl bg-indigo-50 text-indigo-600">
                  <Banknote size={22} />
                </div>
                <span className="rounded-full bg-indigo-50 px-2 py-0.5 text-[11px] font-bold text-indigo-700">
                  Volume
                </span>
              </div>
              <div className="mt-4">
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                  Total Deposits
                </p>
                <p className="mt-1 text-2xl font-black text-slate-900">
                  ${totalDeposits.toLocaleString(undefined, {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2,
                  })}
                </p>
                <p className="mt-1 text-xs text-slate-500">
                  Lifetime deposits transferred
                </p>
              </div>
            </div>

            {/* Total Completed Transactions */}
            <div className="group relative overflow-hidden rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:border-amber-300 hover:shadow-md">
              <div className="flex items-start justify-between">
                <div className="grid h-12 w-12 place-items-center rounded-xl bg-amber-50 text-amber-600">
                  <ReceiptText size={22} />
                </div>
                <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[11px] font-bold text-amber-700">
                  Operations
                </span>
              </div>
              <div className="mt-4">
                <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                  Completed TXs
                </p>
                <p className="mt-1 text-2xl font-black text-slate-900">
                  {totalTransactions.toLocaleString()}
                </p>
                <p className="mt-1 text-xs text-slate-500">
                  Total customer operations
                </p>
              </div>
            </div>
          </div>

          {/* =====================================================
              COUNTER OPERATIONS & CUSTOMER VERIFICATION HUB
          ===================================================== */}
          <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
            {/* Quick Customer Lookup Tool (2 columns) */}
            <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm lg:col-span-2">
              <div className="flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <UserCheck className="text-[#1249AD]" size={20} />
                    <h2 className="text-base font-black text-slate-900 md:text-lg">
                      Quick Customer Verification
                    </h2>
                  </div>
                  <p className="mt-0.5 text-xs text-slate-500">
                    Verify account status, KYC tier, and name before accepting cash
                  </p>
                </div>
                {lookupCustomerData && (
                  <button
                    type="button"
                    onClick={handleResetLookup}
                    className="inline-flex items-center gap-1 rounded-lg px-2.5 py-1 text-xs font-semibold text-slate-500 hover:bg-slate-100 hover:text-slate-800"
                  >
                    <X size={14} />
                    <span>Clear</span>
                  </button>
                )}
              </div>

              {/* Search Form */}
              <form onSubmit={handleQuickLookup} className="mt-4">
                <div className="flex flex-col gap-2.5 sm:flex-row">
                  <div className="relative flex-1">
                    <Search
                      size={17}
                      className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400"
                    />
                    <input
                      type="text"
                      value={lookupPhone}
                      onChange={(e) => setLookupPhone(e.target.value)}
                      placeholder="Enter customer phone (e.g. 098494201)"
                      className="w-full rounded-xl border border-slate-200 bg-slate-50/70 py-2.5 pl-10 pr-4 text-sm text-slate-900 outline-none transition focus:border-[#1249AD] focus:bg-white focus:ring-2 focus:ring-blue-100"
                    />
                  </div>
                  <button
                    type="submit"
                    disabled={lookupSearching || !lookupPhone.trim()}
                    className="inline-flex items-center justify-center gap-2 rounded-xl bg-[#1249AD] px-5 py-2.5 text-sm font-bold text-white shadow-sm transition hover:bg-[#0f3e94] active:scale-95 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    {lookupSearching ? (
                      <>
                        <RefreshCw size={15} className="animate-spin" />
                        <span>Searching...</span>
                      </>
                    ) : (
                      <>
                        <Search size={15} />
                        <span>Verify Customer</span>
                      </>
                    )}
                  </button>
                </div>
              </form>

              {/* Error Alert */}
              {lookupError && (
                <div className="mt-4 flex items-center gap-2.5 rounded-xl border border-amber-200 bg-amber-50 p-3 text-xs font-semibold text-amber-800">
                  <AlertCircle size={16} className="shrink-0 text-amber-600" />
                  <span>{lookupError}</span>
                </div>
              )}

              {/* Customer Lookup Result Card */}
              {lookupCustomerData ? (
                <div className="mt-4 rounded-2xl border border-blue-100 bg-blue-50/40 p-4.5">
                  <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                    <div className="flex items-center gap-3.5">
                      <div className="grid h-12 w-12 place-items-center rounded-2xl bg-[#1249AD] font-bold text-lg text-white shadow-md shadow-blue-500/20">
                        {lookupCustomerData.first_name?.charAt(0)?.toUpperCase() || "C"}
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="font-extrabold text-slate-900 text-base">
                            {lookupCustomerData.first_name} {lookupCustomerData.last_name}
                          </h3>
                          <span className="inline-flex items-center gap-1 rounded-full border border-emerald-200 bg-emerald-50 px-2 py-0.5 text-[11px] font-bold text-emerald-700">
                            <CheckCircle2 size={11} className="text-emerald-500" />
                            {lookupCustomerData.kyc_status === "approved"
                              ? "KYC Verified"
                              : lookupCustomerData.kyc_status || "Active"}
                          </span>
                        </div>
                        <p className="mt-0.5 font-mono text-xs text-slate-600">
                          {lookupCustomerData.phone_number}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-4">
                      <div className="text-right">
                        <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                          Current Balance
                        </p>
                        <p className="text-base font-extrabold text-slate-900">
                          ${Number(lookupCustomerData.balance || 0).toLocaleString(undefined, {
                            minimumFractionDigits: 2,
                            maximumFractionDigits: 2,
                          })}
                        </p>
                      </div>

                      <button
                        type="button"
                        onClick={() =>
                          navigate(
                            `/agent/deposit?phone=${encodeURIComponent(
                              lookupCustomerData.phone_number
                            )}`
                          )
                        }
                        className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-[#1249AD] to-[#0D3885] px-4 py-2.5 text-xs font-bold text-white shadow-md shadow-blue-500/20 transition hover:from-[#0f3e94] hover:to-[#0a2c68] active:scale-95"
                      >
                        <Banknote size={15} />
                        <span>Proceed to Deposit</span>
                        <ArrowRight size={14} />
                      </button>
                    </div>
                  </div>
                </div>
              ) : !lookupError && (
                <div className="mt-4 flex items-center gap-3 rounded-2xl border border-slate-100 bg-slate-50/70 p-3.5 text-xs text-slate-500">
                  <ShieldCheck size={18} className="shrink-0 text-slate-400" />
                  <span>
                    Quickly verify customer registration and KYC status before handling cash.
                    Enter their phone number above to get started.
                  </span>
                </div>
              )}
            </div>

            {/* Counter Guidelines & Security Notice (1 column) */}
            <div className="flex flex-col justify-between rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
              <div>
                <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                  <div className="flex items-center gap-2">
                    <ShieldCheck className="text-emerald-600" size={19} />
                    <h3 className="font-bold text-slate-900 text-sm">
                      Counter Security Policy
                    </h3>
                  </div>
                  <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-slate-600">
                    SOP
                  </span>
                </div>

                <div className="mt-4 space-y-3 text-xs leading-relaxed text-slate-600">
                  <div className="flex items-start gap-2.5">
                    <span className="grid h-5 w-5 shrink-0 place-items-center rounded-full bg-blue-50 text-[11px] font-bold text-[#1249AD]">
                      1
                    </span>
                    <span>
                      Count and inspect physical banknotes for authenticity prior to confirming.
                    </span>
                  </div>

                  <div className="flex items-start gap-2.5">
                    <span className="grid h-5 w-5 shrink-0 place-items-center rounded-full bg-blue-50 text-[11px] font-bold text-[#1249AD]">
                      2
                    </span>
                    <span>
                      Confirm customer full name and registered phone number before disbursing funds.
                    </span>
                  </div>

                  <div className="flex items-start gap-2.5">
                    <span className="grid h-5 w-5 shrink-0 place-items-center rounded-full bg-blue-50 text-[11px] font-bold text-[#1249AD]">
                      3
                    </span>
                    <span>
                      For cash payouts, verify government photo ID against the pickup code holder.
                    </span>
                  </div>
                </div>
              </div>

              <div className="mt-5 pt-3 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-500">
                <span className="font-medium">Need float top-up?</span>
                <span className="font-semibold text-[#1249AD]">Contact Branch Admin</span>
              </div>
            </div>
          </div>

          {/* =====================================================
              RECENT TRANSACTIONS TABLE
          ===================================================== */}
          <div className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm">
            {/* Table Header Bar */}
            <div className="flex flex-col gap-4 border-b border-slate-100 p-5 sm:flex-row sm:items-center sm:justify-between sm:px-6">
              <div>
                <h2 className="text-base font-black text-slate-900 md:text-lg">
                  Recent Deposits & Transactions
                </h2>
                <p className="text-xs text-slate-500">
                  Latest cash operations completed through your counter
                </p>
              </div>

              <div className="flex flex-wrap items-center gap-2.5">
                {/* Search Bar */}
                <div className="relative">
                  <Search
                    size={15}
                    className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
                  />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Search customer, phone, ID..."
                    className="w-full rounded-xl border border-slate-200 bg-slate-50/70 py-1.5 pl-9 pr-3 text-xs text-slate-800 outline-none transition focus:border-[#1249AD] focus:bg-white focus:ring-2 focus:ring-blue-100 sm:w-56"
                  />
                </div>

                {/* Filter Pills */}
                <div className="flex items-center rounded-xl bg-slate-100 p-1 text-xs font-semibold">
                  <button
                    type="button"
                    onClick={() => setStatusFilter("all")}
                    className={`rounded-lg px-2.5 py-1 transition ${
                      statusFilter === "all"
                        ? "bg-white text-slate-900 shadow-xs font-bold"
                        : "text-slate-600 hover:text-slate-900"
                    }`}
                  >
                    All
                  </button>
                  <button
                    type="button"
                    onClick={() => setStatusFilter("success")}
                    className={`rounded-lg px-2.5 py-1 transition ${
                      statusFilter === "success"
                        ? "bg-white text-emerald-700 shadow-xs font-bold"
                        : "text-slate-600 hover:text-slate-900"
                    }`}
                  >
                    Success
                  </button>
                  <button
                    type="button"
                    onClick={() => setStatusFilter("pending")}
                    className={`rounded-lg px-2.5 py-1 transition ${
                      statusFilter === "pending"
                        ? "bg-white text-amber-700 shadow-xs font-bold"
                        : "text-slate-600 hover:text-slate-900"
                    }`}
                  >
                    Pending
                  </button>
                </div>

                {/* Link to Full History */}
                <Link
                  to="/agent/transactions"
                  className="inline-flex items-center gap-1 text-xs font-bold text-[#1249AD] hover:underline"
                >
                  <History size={14} />
                  <span>View All</span>
                </Link>
              </div>
            </div>

            {/* Table Content */}
            {filteredTransactions.length === 0 ? (
              <div className="flex min-h-[220px] flex-col items-center justify-center p-8 text-center">
                <div className="grid h-12 w-12 place-items-center rounded-2xl bg-slate-100 text-slate-400">
                  <ReceiptText size={24} />
                </div>
                <h3 className="mt-3 font-bold text-slate-800 text-sm">
                  {searchQuery ? "No matching transactions" : "No recent deposits yet"}
                </h3>
                <p className="mt-1 max-w-sm text-xs text-slate-500">
                  {searchQuery
                    ? `No transactions matched "${searchQuery}". Clear your search to see all recent deposits.`
                    : "When you complete customer deposits or transfers, they will automatically appear here."}
                </p>
                {searchQuery && (
                  <button
                    type="button"
                    onClick={() => setSearchQuery("")}
                    className="mt-3 rounded-xl border border-slate-200 bg-white px-3.5 py-1.5 text-xs font-bold text-slate-700 hover:bg-slate-50"
                  >
                    Clear Filter
                  </button>
                )}
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full border-collapse text-left">
                  <thead>
                    <tr className="border-b border-slate-100 bg-slate-50/75 text-[11px] font-extrabold uppercase tracking-wider text-slate-500">
                      <th className="px-6 py-3.5">Transaction ID</th>
                      <th className="px-6 py-3.5">Customer</th>
                      <th className="px-6 py-3.5">Phone Number</th>
                      <th className="px-6 py-3.5">Amount</th>
                      <th className="px-6 py-3.5">Status</th>
                      <th className="px-6 py-3.5">Date & Time</th>
                    </tr>
                  </thead>

                  <tbody className="divide-y divide-slate-100 text-sm">
                    {filteredTransactions.map((item, index) => {
                      const txId = item.transaction_id || item.id || `TX-${index}`;
                      const isCopied = copiedId === txId;
                      const status = (item.status || "success").toLowerCase();

                      return (
                        <tr
                          key={txId}
                          className="transition hover:bg-slate-50/80 group"
                        >
                          {/* Transaction ID with Copy */}
                          <td className="whitespace-nowrap px-6 py-4">
                            <div className="flex items-center gap-1.5">
                              <span className="font-mono text-xs font-semibold text-slate-700">
                                {txId}
                              </span>
                              <button
                                type="button"
                                onClick={() => handleCopy(txId)}
                                className="rounded p-1 text-slate-400 opacity-0 transition group-hover:opacity-100 hover:bg-slate-200 hover:text-slate-700"
                                title="Copy Transaction ID"
                              >
                                {isCopied ? (
                                  <Check size={12} className="text-emerald-600" />
                                ) : (
                                  <Copy size={12} />
                                )}
                              </button>
                            </div>
                          </td>

                          {/* Customer */}
                          <td className="whitespace-nowrap px-6 py-4">
                            <div className="flex items-center gap-3">
                              <div className="grid h-8 w-8 place-items-center rounded-full bg-blue-100 font-bold text-xs text-[#1249AD]">
                                {item.customer_name?.charAt(0)?.toUpperCase() || "C"}
                              </div>
                              <span className="font-bold text-slate-900">
                                {item.customer_name || "Customer"}
                              </span>
                            </div>
                          </td>

                          {/* Phone */}
                          <td className="whitespace-nowrap px-6 py-4 font-mono text-xs text-slate-600">
                            {item.customer_phone || item.phone_number || "-"}
                          </td>

                          {/* Amount */}
                          <td className="whitespace-nowrap px-6 py-4">
                            <span className="font-extrabold text-slate-900">
                              ${Number(item.amount || 0).toLocaleString(undefined, {
                                minimumFractionDigits: 2,
                                maximumFractionDigits: 2,
                              })}
                            </span>
                            <span className="ml-1 text-[11px] font-semibold text-slate-400 uppercase">
                              {item.currency || "USD"}
                            </span>
                          </td>

                          {/* Status */}
                          <td className="whitespace-nowrap px-6 py-4">
                            <TransactionBadge status={status} />
                          </td>

                          {/* Date */}
                          <td className="whitespace-nowrap px-6 py-4 text-xs text-slate-500">
                            {formatDateTime(item.created_at)}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}

// =====================================================
// STATUS BADGE COMPONENT
// =====================================================
function TransactionBadge({ status }) {
  const norm = String(status || "").toLowerCase();

  if (norm === "success" || norm === "completed") {
    return (
      <span className="inline-flex items-center gap-1 rounded-full border border-emerald-200 bg-emerald-50 px-2.5 py-1 text-xs font-bold text-emerald-700">
        <CheckCircle2 size={12} className="text-emerald-500" />
        Success
      </span>
    );
  }

  if (norm === "pending") {
    return (
      <span className="inline-flex items-center gap-1 rounded-full border border-amber-200 bg-amber-50 px-2.5 py-1 text-xs font-bold text-amber-700">
        <Clock size={12} className="text-amber-500" />
        Pending
      </span>
    );
  }

  if (norm === "failed" || norm === "rejected") {
    return (
      <span className="inline-flex items-center gap-1 rounded-full border border-red-200 bg-red-50 px-2.5 py-1 text-xs font-bold text-red-600">
        <XCircle size={12} className="text-red-500" />
        Failed
      </span>
    );
  }

  return (
    <span className="inline-flex items-center gap-1 rounded-full border border-slate-200 bg-slate-100 px-2.5 py-1 text-xs font-bold text-slate-600 capitalize">
      {status || "Unknown"}
    </span>
  );
}

// =====================================================
// DATE FORMATTER HELPER
// =====================================================
function formatDateTime(value) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";

  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  }).format(date);
}
