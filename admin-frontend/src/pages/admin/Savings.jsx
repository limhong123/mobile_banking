import { useEffect, useState, useMemo } from "react";
import {
  PiggyBank,
  TrendingUp,
  Coins,
  Users,
  Lock,
  CheckCircle2,
  AlertCircle,
  RefreshCw,
  Sparkles,
  ArrowRight,
  Flame,
  Plus,
  Pencil,
  Trash2,
  X,
  Save,
  Check,
  ShieldAlert,
  Search,
} from "lucide-react";
import {
  getSavingsTerms,
  createSavingsTerm,
  updateSavingsTerm,
  deleteSavingsTerm,
  getSavingsSettings,
  updateSavingsSettings,
  getSavingsOverview,
  simulateSavingsMaturity,
} from "../../api/adminApi";
import StatCard from "../../components/StatCard";

export default function Savings() {
  // Global Settings State
  const [minDeposit, setMinDeposit] = useState("5.0");
  const [maxMonths, setMaxMonths] = useState("48");
  const [isUpdatingSettings, setIsUpdatingSettings] = useState(false);

  // Terms State
  const [terms, setTerms] = useState([]);
  const [warnings, setWarnings] = useState([]);
  const [loading, setLoading] = useState(true);

  // Success / Error Alerts
  const [settingsSuccess, setSettingsSuccess] = useState("");
  const [settingsError, setSettingsError] = useState("");

  // Term Modal State (Create / Edit)
  const [showTermModal, setShowTermModal] = useState(false);
  const [editingTermId, setEditingTermId] = useState(null);
  const [termForm, setTermForm] = useState({
    label: "",
    months: 12,
    ratePercent: "1.5",
    rateUnit: "annual",
    minAmount: "",
    active: true,
    sort: 1,
  });
  const [isSavingTerm, setIsSavingTerm] = useState(false);

  // Overview / Analytics State
  const [stats, setStats] = useState({
    total_active_volume: 0,
    total_projected_interest: 0,
    total_completed_payout: 0,
    active_savings_count: 0,
    completed_savings_count: 0,
    unique_savers_count: 0,
  });
  const [savingsList, setSavingsList] = useState([]);

  // Filtering & Search for User Savings
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [simulatingId, setSimulatingId] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    try {
      setLoading(true);
      const [termsRes, overviewRes] = await Promise.all([
        getSavingsTerms(),
        getSavingsOverview(),
      ]);

      if (termsRes?.data) {
        setTerms(termsRes.data.terms || []);
        setWarnings(termsRes.data.warnings || []);
        if (termsRes.data.settings) {
          setMinDeposit(String(termsRes.data.settings.min_deposit ?? "5.0"));
          setMaxMonths(String(termsRes.data.settings.max_months ?? "48"));
        }
      }

      if (overviewRes?.data) {
        setStats(overviewRes.data.stats || {});
        setSavingsList(overviewRes.data.savings || []);
      }
    } catch (err) {
      console.error("LOAD SAVINGS ERROR:", err);
      setSettingsError(err.response?.data?.detail || "Failed to load savings configuration");
    } finally {
      setLoading(false);
    }
  }

  // =====================================================
  // GLOBAL SETTINGS UPDATE (min_deposit, max_months)
  // =====================================================
  async function handleSaveGlobalSettings(e) {
    e.preventDefault();
    setIsUpdatingSettings(true);
    setSettingsSuccess("");
    setSettingsError("");

    const mDeposit = parseFloat(minDeposit);
    const mMonths = parseInt(maxMonths, 10);

    if (isNaN(mDeposit) || mDeposit <= 0) {
      setSettingsError("Minimum deposit must be greater than $0.00.");
      setIsUpdatingSettings(false);
      return;
    }
    if (isNaN(mMonths) || mMonths < 1) {
      setSettingsError("Maximum months must be at least 1 month.");
      setIsUpdatingSettings(false);
      return;
    }

    try {
      const res = await updateSavingsSettings({
        min_deposit: mDeposit,
        max_months: mMonths,
      });

      setSettingsSuccess("Global savings settings updated successfully!");
      if (res?.warnings) {
        setWarnings(res.warnings);
      }
      setTimeout(() => setSettingsSuccess(""), 4000);
      await loadData();
    } catch (err) {
      console.error("SAVE SETTINGS ERROR:", err);
      setSettingsError(err.response?.data?.detail || "Failed to update global savings settings");
    } finally {
      setIsUpdatingSettings(false);
    }
  }

  // =====================================================
  // TERM CREATE / EDIT MODAL
  // =====================================================
  // Open Create Modal with default max(sort) + 1 and % p.a.
  function openCreateModal() {
    setEditingTermId(null);
    const maxSort = terms.reduce((max, t) => Math.max(max, t.sort || 0), 0);
    setTermForm({
      label: "",
      months: 12,
      ratePercent: "1.5",
      rateUnit: "annual", // Default to % p.a.
      minAmount: "",
      active: true,
      sort: maxSort + 1, // Default new terms' sort = max(sort) + 1
    });
    setSettingsError("");
    setShowTermModal(true);
  }

  function openEditModal(term) {
    setEditingTermId(term.id);
    const percentRate = (term.rate * 100).toFixed(2).replace(/\.00$/, "");
    setTermForm({
      label: term.label || "",
      months: term.months || 1,
      ratePercent: percentRate,
      rateUnit: term.rate_unit || "annual",
      minAmount: term.min_amount != null ? String(term.min_amount) : "",
      active: term.active !== false,
      sort: term.sort || 0,
    });
    setSettingsError("");
    setShowTermModal(true);
  }

  function closeTermModal() {
    setShowTermModal(false);
    setEditingTermId(null);
  }

  // Live Equivalent Rate in Modal Form
  const modalEquivalentRate = useMemo(() => {
    const rawRate = parseFloat(termForm.ratePercent) || 0;
    if (termForm.rateUnit === "annual") {
      const perMonth = rawRate / 12;
      return `${perMonth.toFixed(3)}% per month`;
    } else {
      const perYear = rawRate * 12;
      return `${perYear.toFixed(2)}% p.a. (Annualized)`;
    }
  }, [termForm.ratePercent, termForm.rateUnit]);

  // Live Non-Blocking Warning Check in Modal
  const modalWarning = useMemo(() => {
    if (!showTermModal) return null;
    const m = parseInt(termForm.months, 10);
    const rawRate = parseFloat(termForm.ratePercent);
    if (!m || isNaN(rawRate) || rawRate <= 0 || !termForm.active) return null;
    const decimalRate = rawRate / 100.0;
    const formAnnual = termForm.rateUnit === "annual" ? decimalRate : decimalRate * 12;

    for (const t of terms) {
      if (!t.active || t.id === editingTermId) continue;
      const tAnnual =
        t.annual_equivalent != null
          ? t.annual_equivalent
          : t.rate_unit === "monthly"
          ? t.rate * 12
          : t.rate;
      if (m > t.months && formAnnual < tAnnual) {
        return `${t.label} (${(tAnnual * 100).toFixed(2)}% p.a.) is higher than this term (${(formAnnual * 100).toFixed(2)}% p.a.)`;
      }
      if (m < t.months && formAnnual > tAnnual) {
        return `This term (${(formAnnual * 100).toFixed(2)}% p.a.) is higher than longer term ${t.label} (${(tAnnual * 100).toFixed(2)}% p.a.)`;
      }
    }
    return null;
  }, [
    showTermModal,
    termForm.months,
    termForm.ratePercent,
    termForm.rateUnit,
    termForm.active,
    terms,
    editingTermId,
  ]);

  async function handleSaveTerm(e) {
    e.preventDefault();
    setIsSavingTerm(true);
    setSettingsError("");
    setSettingsSuccess("");

    const m = parseInt(termForm.months, 10);
    const rawRate = parseFloat(termForm.ratePercent);
    const decimalRate = rawRate / 100.0;
    const minAmt = termForm.minAmount ? parseFloat(termForm.minAmount) : null;
    const sortVal = parseInt(termForm.sort, 10) || 0;

    // Validation
    if (!termForm.label.trim()) {
      setSettingsError("Term label cannot be empty.");
      setIsSavingTerm(false);
      return;
    }
    if (isNaN(m) || m < 1) {
      setSettingsError("Months must be an integer greater than 0.");
      setIsSavingTerm(false);
      return;
    }
    const maxM = parseInt(maxMonths, 10) || 48;
    if (m > maxM) {
      setSettingsError(`Months cannot exceed the global maximum of ${maxM} months.`);
      setIsSavingTerm(false);
      return;
    }
    if (isNaN(rawRate) || rawRate <= 0) {
      setSettingsError("Interest rate must be greater than 0%.");
      setIsSavingTerm(false);
      return;
    }
    if (termForm.rateUnit === "annual" && decimalRate > 0.30) {
      setSettingsError("Annual interest rate cannot exceed 30% p.a. (0.30).");
      setIsSavingTerm(false);
      return;
    }
    if (termForm.rateUnit === "monthly" && decimalRate > 0.03) {
      setSettingsError("Monthly interest rate cannot exceed 3% per month (0.03).");
      setIsSavingTerm(false);
      return;
    }
    if (minAmt !== null && (isNaN(minAmt) || minAmt <= 0)) {
      setSettingsError("Minimum amount must be greater than $0.00 if specified.");
      setIsSavingTerm(false);
      return;
    }

    try {
      const payload = {
        label: termForm.label.trim(),
        months: m,
        rate: decimalRate,
        rate_unit: termForm.rateUnit,
        min_amount: minAmt,
        active: termForm.active,
        sort: sortVal,
      };

      if (editingTermId) {
        const res = await updateSavingsTerm(editingTermId, payload);
        setSettingsSuccess(`Term '${payload.label}' updated successfully!`);
        if (res?.warnings) setWarnings(res.warnings);
      } else {
        const res = await createSavingsTerm(payload);
        setSettingsSuccess(`Term '${payload.label}' created successfully!`);
        if (res?.warnings) setWarnings(res.warnings);
      }

      closeTermModal();
      setTimeout(() => setSettingsSuccess(""), 4000);
      await loadData();
    } catch (err) {
      console.error("SAVE TERM ERROR:", err);
      setSettingsError(err.response?.data?.detail || "Failed to save savings term");
    } finally {
      setIsSavingTerm(false);
    }
  }

  async function handleToggleActive(term) {
    try {
      setSettingsError("");
      const newActive = !term.active;
      const res = await updateSavingsTerm(term.id, { active: newActive });
      setSettingsSuccess(`Term '${term.label}' is now ${newActive ? "Active" : "Inactive"}.`);
      if (res?.warnings) setWarnings(res.warnings);
      setTimeout(() => setSettingsSuccess(""), 4000);
      await loadData();
    } catch (err) {
      console.error("TOGGLE TERM ERROR:", err);
      setSettingsError(err.response?.data?.detail || "Failed to update term status");
      setTimeout(() => setSettingsError(""), 5000);
    }
  }

  async function handleDeleteTerm(term) {
    const confirm = window.confirm(
      `Are you sure you want to deactivate (soft-delete) term '${term.label}'? It will no longer be available for new customer deposits.`
    );
    if (!confirm) return;

    try {
      setSettingsError("");
      const res = await deleteSavingsTerm(term.id);
      setSettingsSuccess(`Term '${term.label}' has been deactivated (soft-deleted).`);
      if (res?.warnings) setWarnings(res.warnings);
      setTimeout(() => setSettingsSuccess(""), 4000);
      await loadData();
    } catch (err) {
      console.error("DELETE TERM ERROR:", err);
      setSettingsError(err.response?.data?.detail || "Failed to delete term");
      setTimeout(() => setSettingsError(""), 5000);
    }
  }

  async function handleSimulatePayout(item) {
    const targetId = item.id || item.saving_id;
    try {
      setSimulatingId(targetId);
      await simulateSavingsMaturity(targetId);
      setSettingsSuccess(`Successfully simulated maturity payout for ${item.saving_id || item.user_name}!`);
      setTimeout(() => setSettingsSuccess(""), 4000);
      await loadData();
    } catch (err) {
      console.error("SIMULATE MATURITY ERROR:", err);
      setSettingsError(err.response?.data?.detail || "Simulation failed");
      setTimeout(() => setSettingsError(""), 5000);
    } finally {
      setSimulatingId(null);
    }
  }

  // =====================================================
  // DYNAMIC LIVE RETURN SIMULATOR ON $1,000 DEPOSIT
  // =====================================================
  // Enforce sorted terms: ordered by sort asc, and by months asc when sort is equal
  const sortedTerms = useMemo(() => {
    return [...terms].sort((a, b) => {
      const sA = a.sort ?? 0;
      const sB = b.sort ?? 0;
      if (sA !== sB) return sA - sB;
      return (a.months ?? 0) - (b.months ?? 0);
    });
  }, [terms]);

  const activeTerms = useMemo(() => {
    return sortedTerms.filter((t) => t.active);
  }, [sortedTerms]);

  // Find the term with the highest effective annual equivalent (always p.a.)
  const bestRateTermId = useMemo(() => {
    if (activeTerms.length === 0) return null;
    let highest = activeTerms[0];
    for (const t of activeTerms) {
      const tAnnual = t.annual_equivalent ?? (t.rate_unit === "monthly" ? t.rate * 12 : t.rate);
      const hAnnual = highest.annual_equivalent ?? (highest.rate_unit === "monthly" ? highest.rate * 12 : highest.rate);
      if (tAnnual > hAnnual) {
        highest = t;
      }
    }
    return highest?.id;
  }, [activeTerms]);

  // Counts for tabs
  const allCount = savingsList.length;
  const activeCount = savingsList.filter((s) => s.status === "active").length;
  const completedCount = savingsList.filter(
    (s) => s.status === "completed" || s.status === "matured"
  ).length;

  // Filtered customer savings
  const filteredSavings = savingsList.filter((item) => {
    const query = searchQuery.toLowerCase().trim();
    const matchesSearch =
      !query ||
      (item.user_name || "").toLowerCase().includes(query) ||
      (item.phone_number || "").includes(query) ||
      (item.saving_id || "").toLowerCase().includes(query) ||
      (item.term || "").toLowerCase().includes(query) ||
      (item.label || "").toLowerCase().includes(query) ||
      (item.status || "").toLowerCase().includes(query);

    if (statusFilter === "active") {
      return matchesSearch && item.status === "active";
    }
    if (statusFilter === "completed") {
      return matchesSearch && (item.status === "completed" || item.status === "matured");
    }
    return matchesSearch;
  });

  return (
    <div className="space-y-8 pb-12">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="flex items-center gap-3 text-2xl font-black text-slate-900 sm:text-3xl">
            <span className="grid h-11 w-11 place-items-center rounded-2xl bg-emerald-500 text-white shadow-lg shadow-emerald-500/30">
              <PiggyBank size={24} />
            </span>
            Savings & Term Deposits
          </h1>
          <p className="mt-1 text-sm font-medium text-slate-500">
            Admin full control over savings terms, interest rates, durations, and customer time deposits.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={openCreateModal}
            className="inline-flex items-center gap-2 rounded-xl bg-emerald-600 px-4 py-2.5 text-sm font-bold text-white shadow-md shadow-emerald-600/20 transition hover:bg-emerald-700 active:scale-95"
          >
            <Plus size={18} />
            Add Term
          </button>

          <button
            onClick={loadData}
            disabled={loading}
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50 hover:text-slate-900 disabled:opacity-50"
          >
            <RefreshCw size={16} className={loading ? "animate-spin" : ""} />
            Refresh
          </button>
        </div>
      </div>

      {/* Global Alerts: Success & Errors */}
      {settingsSuccess && (
        <div className="flex items-center gap-2.5 rounded-2xl bg-emerald-50 border border-emerald-200 p-4 text-sm font-bold text-emerald-800 shadow-sm">
          <CheckCircle2 size={19} className="text-emerald-600 shrink-0" />
          <span>{settingsSuccess}</span>
        </div>
      )}
      {settingsError && (
        <div className="flex items-center gap-2.5 rounded-2xl bg-rose-50 border border-rose-200 p-4 text-sm font-bold text-rose-800 shadow-sm">
          <AlertCircle size={19} className="text-rose-600 shrink-0" />
          <span>{settingsError}</span>
        </div>
      )}

      {/* Non-Blocking Rate Hierarchy Warnings */}
      {warnings && warnings.length > 0 && (
        <div className="rounded-2xl bg-amber-50 border-2 border-amber-300 p-5 shadow-sm space-y-2">
          <div className="flex items-center gap-2 text-xs font-black uppercase tracking-wider text-amber-900">
            <ShieldAlert size={18} className="text-amber-600 shrink-0" />
            <span>Rate Hierarchy Warnings ({warnings.length} non-blocking {warnings.length === 1 ? "conflict" : "conflicts"})</span>
          </div>
          <p className="text-xs text-amber-800">
            The following longer-duration active terms have a lower annual-equivalent return than shorter terms:
          </p>
          <ul className="list-disc pl-5 space-y-1.5 text-xs font-bold text-amber-950">
            {warnings.map((w, idx) => (
              <li key={idx}>{w}</li>
            ))}
          </ul>
        </div>
      )}

      {/* =====================================================
          GLOBAL SETTINGS BAR (Min Deposit, Max Months)
      ===================================================== */}
      <div className="rounded-3xl border border-slate-200/80 bg-white p-6 shadow-sm">
        <form onSubmit={handleSaveGlobalSettings} className="flex flex-col sm:flex-row sm:items-center justify-between gap-5">
          <div>
            <h3 className="text-base font-black text-slate-900">Global Savings Settings</h3>
            <p className="mt-0.5 text-xs text-slate-500">
              Default minimum threshold and tenure limit across all savings terms
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-4">
            {/* Global Min Deposit */}
            <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50/70 px-3 py-2 text-xs font-bold text-slate-700">
              <span>Min Deposit:</span>
              <span className="text-slate-400">$</span>
              <input
                type="number"
                step="0.1"
                min="0.1"
                value={minDeposit}
                onChange={(e) => setMinDeposit(e.target.value)}
                required
                className="w-16 bg-transparent font-black text-slate-900 outline-none text-sm"
              />
            </div>

            {/* Global Max Months */}
            <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50/70 px-3 py-2 text-xs font-bold text-slate-700">
              <span>Max Months:</span>
              <input
                type="number"
                step="1"
                min="1"
                max="120"
                value={maxMonths}
                onChange={(e) => setMaxMonths(e.target.value)}
                required
                className="w-14 bg-transparent font-black text-slate-900 outline-none text-sm"
              />
              <span className="text-slate-400">mo</span>
            </div>

            <button
              type="submit"
              disabled={isUpdatingSettings}
              className="inline-flex items-center gap-1.5 rounded-xl bg-slate-900 px-4 py-2 text-xs font-bold text-white shadow-sm transition hover:bg-slate-800 disabled:opacity-50"
            >
              {isUpdatingSettings ? (
                <RefreshCw size={14} className="animate-spin" />
              ) : (
                <Save size={14} />
              )}
              Save Settings
            </button>
          </div>
        </form>
      </div>

      {/* =====================================================
          DYNAMIC TERMS TABLE (ADMIN FULL CONTROL)
      ===================================================== */}
      <div className="overflow-hidden rounded-3xl border border-slate-200/80 bg-white shadow-xl shadow-slate-100">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 border-b border-slate-100 p-6">
          <div>
            <h2 className="text-lg font-black text-slate-900">Savings Terms & Rate Control</h2>
            <p className="mt-0.5 text-xs text-slate-500">
              Fully customize term durations, units (% p.a. or % /mo), minimum amounts, and sort order.
            </p>
          </div>
          <button
            onClick={openCreateModal}
            className="inline-flex items-center gap-2 rounded-xl bg-emerald-600 px-4 py-2 text-xs font-bold text-white shadow-sm transition hover:bg-emerald-700 active:scale-95 self-start sm:self-auto"
          >
            <Plus size={16} />
            <span>Add New Term</span>
          </button>
        </div>

        {terms.length === 0 ? (
          <div className="flex min-h-[200px] flex-col items-center justify-center p-8 text-center">
            <PiggyBank size={32} className="text-slate-300" />
            <p className="mt-3 text-sm font-bold text-slate-700">No savings terms found</p>
            <p className="mt-1 text-xs text-slate-500">Click Add Term to create the first term.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse">
              <thead className="bg-slate-50/80">
                <tr className="text-left text-xs font-bold uppercase tracking-wider text-slate-500 border-b border-slate-100">
                  <th className="px-5 py-4">Sort</th>
                  <th className="px-5 py-4">Label</th>
                  <th className="px-5 py-4">Months</th>
                  <th className="px-5 py-4">Interest Rate</th>
                  <th className="px-5 py-4">Rate Unit</th>
                  <th className="px-5 py-4">Annual equivalent</th>
                  <th className="px-5 py-4">Min Amount</th>
                  <th className="px-5 py-4">Status</th>
                  <th className="px-5 py-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-sm">
                {sortedTerms.map((t) => {
                  const ratePercent = (t.rate * 100).toFixed(2);
                  const isBest = t.id === bestRateTermId && t.active;
                  const unitDisplay = t.rate_unit === "annual" ? "% p.a." : "% /mo";
                  const annualEquivalentNum =
                    t.annual_equivalent != null
                      ? t.annual_equivalent
                      : t.rate_unit === "monthly"
                      ? t.rate * 12
                      : t.rate;
                  const annualEquivalentDisplay = `${(annualEquivalentNum * 100).toFixed(2)}% p.a.`;

                  return (
                    <tr
                      key={t.id}
                      className={`transition hover:bg-slate-50/70 ${
                        !t.active ? "opacity-60 bg-slate-50/40" : ""
                      }`}
                    >
                      <td className="px-5 py-4 font-mono text-xs text-slate-400">
                        {t.sort}
                      </td>

                      <td className="px-5 py-4">
                        <span className="font-extrabold text-slate-900">{t.label}</span>
                      </td>

                      <td className="px-5 py-4 font-mono font-bold text-slate-700">
                        {t.months} mo
                      </td>

                      <td className="px-5 py-4 font-mono text-base font-black text-slate-900">
                        <span className={t.rate_unit === "annual" ? "text-indigo-600" : "text-emerald-600"}>
                          {ratePercent}%
                        </span>
                      </td>

                      <td className="px-5 py-4">
                        <span
                          className={`inline-flex rounded-md px-2 py-0.5 text-xs font-bold ${
                            t.rate_unit === "annual"
                              ? "bg-indigo-50 text-indigo-700 border border-indigo-200"
                              : "bg-emerald-50 text-emerald-700 border border-emerald-200"
                          }`}
                        >
                          {unitDisplay}
                        </span>
                      </td>

                      <td className="px-5 py-4">
                        <div className="flex items-center gap-2">
                          <span className="font-mono text-xs font-black text-slate-900 bg-slate-100 rounded-lg px-2.5 py-1">
                            {annualEquivalentDisplay}
                          </span>
                          {isBest && (
                            <span className="inline-flex items-center gap-1 rounded-full bg-emerald-500 text-white px-2 py-0.5 text-[10px] font-black uppercase tracking-wider shadow-sm">
                              <Flame size={10} />
                              BEST RATE
                            </span>
                          )}
                        </div>
                      </td>

                      <td className="px-5 py-4 font-mono text-xs font-bold text-slate-700">
                        ${Number(t.min_amount || minDeposit).toFixed(2)}
                      </td>

                      <td className="px-5 py-4">
                        <button
                          type="button"
                          onClick={() => handleToggleActive(t)}
                          className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-bold transition ${
                            t.active
                              ? "bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100"
                              : "bg-slate-100 text-slate-500 hover:bg-slate-200"
                          }`}
                          title="Click to toggle active status"
                        >
                          <span
                            className={`h-1.5 w-1.5 rounded-full ${
                              t.active ? "bg-emerald-500" : "bg-slate-400"
                            }`}
                          />
                          {t.active ? "Active" : "Disabled"}
                        </button>
                      </td>

                      <td className="px-5 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            type="button"
                            onClick={() => openEditModal(t)}
                            className="rounded-lg p-1.5 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
                            title="Edit Term"
                          >
                            <Pencil size={15} />
                          </button>
                          <button
                            type="button"
                            onClick={() => handleDeleteTerm(t)}
                            className="rounded-lg p-1.5 text-slate-400 transition hover:bg-rose-50 hover:text-rose-600"
                            title="Soft Delete (Deactivate) Term"
                          >
                            <Trash2 size={15} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* =====================================================
          DYNAMIC LIVE RETURN BANNER (ON $1,000 DEPOSIT)
      ===================================================== */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-5 rounded-3xl bg-gradient-to-r from-slate-900 via-indigo-950 to-blue-950 p-6 text-white shadow-xl">
        <div className="flex items-center gap-3.5">
          <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-white/10 text-emerald-400">
            <Sparkles size={22} />
          </div>
          <div>
            <div className="text-xs font-extrabold uppercase tracking-wider text-emerald-400">
              Live Return Simulation ($1,000 Deposit)
            </div>
            <div className="text-sm font-medium text-slate-300">
              Guaranteed customer earnings computed dynamically from active terms
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3 overflow-x-auto pb-1">
          {activeTerms.map((t) => {
            const isBest = t.id === bestRateTermId;
            const p = 1000.0;
            const r = t.rate;
            const m = t.months;
            const interest =
              t.rate_unit === "annual" ? (p * r * m) / 12 : p * r * m;

            return (
              <div
                key={t.id}
                className={`shrink-0 rounded-2xl px-4 py-2.5 text-center transition ${
                  isBest
                    ? "bg-emerald-500/25 border-2 border-emerald-400 text-white"
                    : "bg-white/10 border border-white/10"
                }`}
              >
                <div className="flex items-center justify-center gap-1 text-[11px] font-bold text-slate-200">
                  <span>{t.label}</span>
                  {isBest && <Flame size={12} className="text-emerald-400" />}
                </div>
                <div
                  className={`text-base font-black mt-0.5 ${
                    isBest ? "text-emerald-300" : "text-white"
                  }`}
                >
                  +${interest.toFixed(2)}
                </div>
                <div className="text-[10px] text-slate-400 font-mono">
                  {(t.rate * 100).toFixed(2)}% {t.rate_unit === "annual" ? "p.a." : "/mo"}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* =====================================================
          CUSTOMER SAVINGS STATS CARDS
      ===================================================== */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Locked Savings"
          value={`$${Number(stats.total_active_volume || 0).toLocaleString("en-US", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          })}`}
          icon={Coins}
          iconStyle="bg-emerald-500/10 text-emerald-600"
          description="Funds currently locked in customer savings"
        />

        <StatCard
          title="Projected Interest"
          value={`$${Number(stats.total_projected_interest || 0).toLocaleString("en-US", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          })}`}
          icon={TrendingUp}
          iconStyle="bg-indigo-500/10 text-indigo-600"
          description="Total interest due to savers upon maturity"
        />

        <StatCard
          title="Active Savings Deposits"
          value={stats.active_savings_count || 0}
          icon={Lock}
          iconStyle="bg-amber-500/10 text-amber-600"
          description="Deposits actively earning interest"
        />

        <StatCard
          title="Unique Savers"
          value={stats.unique_savers_count || 0}
          icon={Users}
          iconStyle="bg-sky-500/10 text-sky-600"
          description="Customers with active savings"
        />
      </div>

      {/* =====================================================
          CUSTOMER SAVINGS DEPOSITS TABLE
      ===================================================== */}
      <div className="overflow-hidden rounded-3xl border border-slate-200/80 bg-white shadow-xl shadow-slate-100">
        <div className="flex flex-col gap-4 border-b border-slate-100 p-6 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h3 className="text-lg font-bold text-slate-900">Customer Savings Accounts</h3>
            <p className="text-xs font-medium text-slate-500">
              Users cannot withdraw money while savings deposit is actively locked
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <div className="flex rounded-xl bg-slate-100 p-1">
              <button
                onClick={() => setStatusFilter("all")}
                className={`rounded-lg px-3 py-1.5 text-xs font-bold transition ${
                  statusFilter === "all"
                    ? "bg-white text-slate-900 shadow-sm"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                All ({allCount})
              </button>
              <button
                onClick={() => setStatusFilter("active")}
                className={`rounded-lg px-3 py-1.5 text-xs font-bold transition ${
                  statusFilter === "active"
                    ? "bg-white text-slate-900 shadow-sm"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Active ({activeCount})
              </button>
              <button
                onClick={() => setStatusFilter("completed")}
                className={`rounded-lg px-3 py-1.5 text-xs font-bold transition ${
                  statusFilter === "completed"
                    ? "bg-white text-slate-900 shadow-sm"
                    : "text-slate-600 hover:text-slate-900"
                }`}
              >
                Completed ({completedCount})
              </button>
            </div>

            <div className="relative">
              <Search
                size={16}
                className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
              />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search user, phone..."
                className="w-48 sm:w-64 rounded-xl border border-slate-200 py-1.5 pl-9 pr-4 text-xs font-medium text-slate-800 placeholder-slate-400 focus:border-indigo-500 focus:outline-none"
              />
            </div>
          </div>
        </div>

        {filteredSavings.length === 0 ? (
          <div className="flex min-h-[220px] flex-col items-center justify-center p-8 text-center">
            <Coins size={36} className="text-slate-300" />
            <p className="mt-3 text-sm font-bold text-slate-700">No savings records found</p>
            <p className="mt-1 text-xs text-slate-500">
              Customer deposits will show up here as soon as they open savings accounts.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse">
              <thead className="bg-slate-50/80">
                <tr className="text-left text-xs font-bold uppercase tracking-wider text-slate-500 border-b border-slate-100">
                  <th className="px-6 py-4">Customer</th>
                  <th className="px-6 py-4">Principal</th>
                  <th className="px-6 py-4">Term & Rate</th>
                  <th className="px-6 py-4">Interest</th>
                  <th className="px-6 py-4">Total Payout</th>
                  <th className="px-6 py-4">Maturity Date</th>
                  <th className="px-6 py-4">Status</th>
                  <th className="px-6 py-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-sm">
                {filteredSavings.map((item) => {
                  const isSimulating = simulatingId === (item.id || item.saving_id);
                  const isCompleted = item.status === "completed" || item.status === "matured";

                  return (
                    <tr key={item.id || item.saving_id} className="transition hover:bg-slate-50/70">
                      <td className="px-6 py-4">
                        <div className="font-extrabold text-slate-900">{item.user_name}</div>
                        <div className="text-xs font-mono text-slate-400">
                          {item.phone_number || item.saving_id}
                        </div>
                      </td>

                      <td className="px-6 py-4 font-mono font-bold text-slate-900">
                        ${Number(item.principal || item.principal_amount || 0).toFixed(2)}
                      </td>

                      <td className="px-6 py-4 text-xs font-medium text-slate-700">
                        <span className="rounded-md bg-slate-100 px-2 py-1 font-semibold text-slate-800">
                          {item.label || item.term}
                        </span>
                        <span className="ml-2 font-bold text-indigo-600">
                          {Number(item.rate || item.interest_rate || 0) * (item.rate <= 0.3 ? 100 : 1)}%
                        </span>
                      </td>

                      <td className="px-6 py-4 font-mono font-bold text-emerald-600">
                        +${Number(item.interest_amount || item.expected_interest || 0).toFixed(2)}
                      </td>

                      <td className="px-6 py-4 font-mono font-extrabold text-slate-900">
                        ${Number(item.total_payout || 0).toFixed(2)}
                      </td>

                      <td className="px-6 py-4 text-xs text-slate-500 font-medium">
                        {item.maturity_date ? new Date(item.maturity_date).toLocaleDateString() : "-"}
                      </td>

                      <td className="px-6 py-4">
                        <span
                          className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-bold ${
                            isCompleted
                              ? "bg-slate-100 text-slate-600"
                              : "bg-emerald-50 text-emerald-700 border border-emerald-200"
                          }`}
                        >
                          <span
                            className={`h-1.5 w-1.5 rounded-full ${
                              isCompleted ? "bg-slate-400" : "bg-emerald-500 animate-pulse"
                            }`}
                          />
                          {isCompleted ? "Matured" : "Active (Locked)"}
                        </span>
                      </td>

                      <td className="px-6 py-4 text-right">
                        {!isCompleted && (
                          <button
                            type="button"
                            disabled={isSimulating}
                            onClick={() => handleSimulatePayout(item)}
                            className="inline-flex items-center gap-1.5 rounded-xl bg-indigo-50 border border-indigo-200 px-3 py-1.5 text-xs font-bold text-indigo-700 transition hover:bg-indigo-100 active:scale-95 disabled:opacity-50"
                            title="Simulate immediate maturity payout for dev/testing"
                          >
                            {isSimulating ? (
                              <RefreshCw size={13} className="animate-spin" />
                            ) : (
                              <ArrowRight size={13} />
                            )}
                            <span>Simulate Payout</span>
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* =====================================================
          ADD / EDIT TERM MODAL
      ===================================================== */}
      {showTermModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
          <div className="w-full max-w-lg rounded-3xl bg-white p-6 shadow-2xl sm:p-8 space-y-6">
            <div className="flex items-center justify-between border-b border-slate-100 pb-4">
              <div>
                <h3 className="text-xl font-black text-slate-900">
                  {editingTermId ? "Edit Savings Term" : "Add New Savings Term"}
                </h3>
                <p className="mt-0.5 text-xs text-slate-500">
                  {editingTermId
                    ? "Update term rates and parameters. Existing deposits remain locked."
                    : "Create a new term with customized duration and interest rate."}
                </p>
              </div>
              <button
                type="button"
                onClick={closeTermModal}
                className="rounded-xl p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700"
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveTerm} className="space-y-4">
              {/* Term Label */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                  Term Label *
                </label>
                <input
                  type="text"
                  value={termForm.label}
                  onChange={(e) => setTermForm({ ...termForm, label: e.target.value })}
                  placeholder="e.g. 1 Year, 6 Months High Yield"
                  required
                  className="w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm font-semibold text-slate-900 outline-none focus:border-emerald-600 focus:ring-2 focus:ring-emerald-100"
                />
              </div>

              {/* Months & Unit in 2 cols */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                    Duration (Months) *
                  </label>
                  <input
                    type="number"
                    min="1"
                    max={maxMonths}
                    value={termForm.months}
                    onChange={(e) =>
                      setTermForm({ ...termForm, months: parseInt(e.target.value, 10) || 1 })
                    }
                    required
                    className="w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm font-semibold text-slate-900 outline-none focus:border-emerald-600 focus:ring-2 focus:ring-emerald-100"
                  />
                  <span className="mt-1 block text-[11px] text-slate-400">
                    Max: {maxMonths} months
                  </span>
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                    Rate Unit *
                  </label>
                  <select
                    value={termForm.rateUnit}
                    onChange={(e) => setTermForm({ ...termForm, rateUnit: e.target.value })}
                    className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm font-bold text-slate-900 outline-none bg-white focus:border-emerald-600 focus:ring-2 focus:ring-emerald-100"
                  >
                    <option value="annual">% p.a.</option>
                    <option value="monthly">% per month</option>
                  </select>
                  <p className="mt-1.5 text-[11px] font-medium text-amber-700">
                    Tip: use % p.a. for all terms so rates are easy to compare.
                  </p>
                </div>
              </div>

              {/* Rate & Live Equivalent */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                    Interest Rate (%) *
                  </label>
                  <div className="relative">
                    <input
                      type="number"
                      step="0.01"
                      min="0.01"
                      max={termForm.rateUnit === "annual" ? "30" : "3"}
                      value={termForm.ratePercent}
                      onChange={(e) => setTermForm({ ...termForm, ratePercent: e.target.value })}
                      required
                      placeholder={termForm.rateUnit === "annual" ? "1.5" : "0.5"}
                      className="w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm font-black text-slate-900 outline-none focus:border-emerald-600 focus:ring-2 focus:ring-emerald-100"
                    />
                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">
                      {termForm.rateUnit === "annual" ? "% p.a." : "% /mo"}
                    </span>
                  </div>
                  <span className="mt-1 block text-[11px] text-slate-400">
                    {termForm.rateUnit === "annual" ? "Max 30% p.a." : "Max 3% /mo"}
                  </span>
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                    Equivalent (Live)
                  </label>
                  <div className="rounded-xl border border-slate-100 bg-slate-50 px-3.5 py-2.5 text-xs font-bold text-indigo-700">
                    {modalEquivalentRate}
                  </div>
                  <span className="mt-1 block text-[11px] text-slate-400">
                    Auto-converted equivalent
                  </span>
                </div>
              </div>

              {/* Min Amount & Sort */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                    Min Amount (Optional)
                  </label>
                  <div className="relative">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">
                      $
                    </span>
                    <input
                      type="number"
                      step="0.1"
                      min="0.1"
                      value={termForm.minAmount}
                      onChange={(e) => setTermForm({ ...termForm, minAmount: e.target.value })}
                      placeholder={`Default: $${minDeposit}`}
                      className="w-full rounded-xl border border-slate-200 pl-7 pr-3.5 py-2.5 text-sm font-semibold text-slate-900 outline-none focus:border-emerald-600 focus:ring-2 focus:ring-emerald-100"
                    />
                  </div>
                  <span className="mt-1 block text-[11px] text-slate-400">
                    Leave blank for global default (${minDeposit})
                  </span>
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                    Sort Order
                  </label>
                  <input
                    type="number"
                    value={termForm.sort}
                    onChange={(e) =>
                      setTermForm({ ...termForm, sort: parseInt(e.target.value, 10) || 0 })
                    }
                    className="w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm font-semibold text-slate-900 outline-none focus:border-emerald-600 focus:ring-2 focus:ring-emerald-100"
                  />
                  <span className="mt-1 block text-[11px] text-slate-400">
                    Lower numbers display first
                  </span>
                </div>
              </div>

              {/* Active Toggle */}
              <div className="flex items-center gap-3 pt-2">
                <input
                  type="checkbox"
                  id="termActive"
                  checked={termForm.active}
                  onChange={(e) => setTermForm({ ...termForm, active: e.target.checked })}
                  className="h-4 w-4 rounded border-slate-300 text-emerald-600 focus:ring-emerald-500"
                />
                <label htmlFor="termActive" className="text-xs font-bold text-slate-700 cursor-pointer">
                  Active (immediately available for new customer deposits)
                </label>
              </div>

              {/* Live Non-Blocking Warning in Modal */}
              {modalWarning && (
                <div className="rounded-xl border border-amber-300 bg-amber-50 p-3 text-xs text-amber-950 flex items-start gap-2 shadow-xs">
                  <ShieldAlert size={16} className="text-amber-600 shrink-0 mt-0.5" />
                  <div>
                    <span className="font-black text-amber-900">Rate Advisory: </span>
                    <span className="font-semibold">{modalWarning}</span>
                  </div>
                </div>
              )}

              {/* Modal Buttons */}
              <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={closeTermModal}
                  className="rounded-xl border border-slate-200 px-4 py-2.5 text-xs font-bold text-slate-600 hover:bg-slate-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSavingTerm}
                  className="inline-flex items-center gap-2 rounded-xl bg-emerald-600 px-5 py-2.5 text-xs font-bold text-white shadow-md shadow-emerald-600/20 hover:bg-emerald-700 disabled:opacity-50"
                >
                  {isSavingTerm ? (
                    <RefreshCw size={14} className="animate-spin" />
                  ) : (
                    <Check size={14} />
                  )}
                  {editingTermId ? "Save Changes" : "Create Term"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
