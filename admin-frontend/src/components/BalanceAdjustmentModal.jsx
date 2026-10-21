import { useState, useId } from "react";
import {
  X,
  PlusCircle,
  MinusCircle,
  AlertCircle,
  CheckCircle2,
  Wallet,
  ArrowRight,
  ShieldCheck,
} from "lucide-react";
import {
  creditUser,
  debitUser,
  creditAgent,
  debitAgent,
} from "../api/adminApi";

export default function BalanceAdjustmentModal({
  isOpen,
  onClose,
  target, // { id, name, phone, balance, currency, type: "user" | "agent" }
  onSuccess,
}) {
  const [adjustmentType, setAdjustmentType] = useState("credit"); // "credit" | "debit"
  const [amount, setAmount] = useState("");
  const [description, setDescription] = useState("");
  const [reference, setReference] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");
  const formId = useId();

  if (!isOpen || !target) return null;

  const currentBalance = Number(target.balance || 0);
  const numAmount = Number(amount || 0);
  const isCredit = adjustmentType === "credit";

  const newBalance = isCredit
    ? currentBalance + (Number.isFinite(numAmount) ? numAmount : 0)
    : Math.max(0, currentBalance - (Number.isFinite(numAmount) ? numAmount : 0));

  const isOverdraft = !isCredit && numAmount > currentBalance;

  const quickAmounts = [10, 25, 50, 100, 250, 500];

  const creditPresets = [
    "Deposit Correction",
    "Dispute Refund",
    "Promotional Bonus",
    "System Adjustment",
  ];

  const debitPresets = [
    "Duplicate Reversal",
    "Dispute Chargeback",
    "Fee Adjustment",
    "Compliance Deduction",
  ];

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");
    setSuccessMsg("");

    if (!numAmount || numAmount <= 0) {
      setError("Please enter a valid amount greater than $0");
      return;
    }

    if (isOverdraft) {
      setError(
        `Cannot debit $${numAmount.toFixed(2)}. Available balance is only $${currentBalance.toFixed(2)}.`
      );
      return;
    }

    try {
      setLoading(true);

      const payload = {
        amount: numAmount,
        description: description.trim() || undefined,
        reference: reference.trim() || undefined,
      };

      let response;
      if (target.type === "agent") {
        response = isCredit
          ? await creditAgent(target.id, payload)
          : await debitAgent(target.id, payload);
      } else {
        response = isCredit
          ? await creditUser(target.id, payload)
          : await debitUser(target.id, payload);
      }

      setSuccessMsg(
        response?.message ||
          `Successfully ${isCredit ? "credited" : "debited"} $${numAmount.toFixed(2)}`
      );

      setTimeout(() => {
        setSuccessMsg("");
        setAmount("");
        setDescription("");
        setReference("");
        onClose();
        if (onSuccess) onSuccess();
      }, 900);
    } catch (err) {
      console.error("BALANCE ADJUSTMENT ERROR:", err);
      const detail = err.response?.data?.detail;
      setError(
        typeof detail === "string"
          ? detail
          : detail?.message || "Failed to process balance adjustment"
      );
    } finally {
      setLoading(false);
    }
  }

  function handleQuickPreset(text) {
    setDescription(text);
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-xs">
      <div
        className="relative w-full max-w-lg overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl transition-all"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-100 px-6 py-4">
          <div className="flex items-center gap-2.5">
            <div
              className={`flex h-9 w-9 items-center justify-center rounded-xl ${
                isCredit ? "bg-emerald-50 text-emerald-600" : "bg-rose-50 text-rose-600"
              }`}
            >
              <Wallet size={19} />
            </div>
            <div>
              <h3 className="text-base font-bold text-slate-900">
                Balance Adjustment
              </h3>
              <p className="text-xs text-slate-400">
                Manual Credit / Debit Operations
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-1.5 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600"
          >
            <X size={18} />
          </button>
        </div>

        {/* Target Profile strip */}
        <div className="border-b border-slate-100 bg-slate-50/70 px-6 py-3.5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-blue-100 text-sm font-black text-blue-700">
                {target.name?.charAt(0).toUpperCase() || "U"}
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <p className="font-bold text-slate-900">{target.name}</p>
                  <span className="rounded-full bg-slate-200/80 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-slate-600">
                    {target.type === "agent" ? "Agent" : "Customer"}
                  </span>
                </div>
                <p className="text-xs text-slate-500">{target.phone || "-"}</p>
              </div>
            </div>

            <div className="text-right">
              <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                Current Balance
              </p>
              <p className="text-base font-extrabold text-slate-900">
                ${currentBalance.toLocaleString(undefined, {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2,
                })}
              </p>
            </div>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          {/* Action Tabs: Credit vs Debit */}
          <div className="grid grid-cols-2 gap-2 rounded-xl bg-slate-100 p-1.5">
            <button
              type="button"
              onClick={() => {
                setAdjustmentType("credit");
                setError("");
              }}
              className={`flex items-center justify-center gap-2 rounded-lg py-2.5 text-xs font-bold transition ${
                isCredit
                  ? "bg-white text-emerald-700 shadow-sm"
                  : "text-slate-500 hover:text-slate-900"
              }`}
            >
              <PlusCircle size={15} />
              <span>Credit (+ Add)</span>
            </button>

            <button
              type="button"
              onClick={() => {
                setAdjustmentType("debit");
                setError("");
              }}
              className={`flex items-center justify-center gap-2 rounded-lg py-2.5 text-xs font-bold transition ${
                !isCredit
                  ? "bg-white text-rose-700 shadow-sm"
                  : "text-slate-500 hover:text-slate-900"
              }`}
            >
              <MinusCircle size={15} />
              <span>Debit (- Deduct)</span>
            </button>
          </div>

          {/* Messages */}
          {error && (
            <div className="flex items-start gap-2.5 rounded-xl border border-rose-200 bg-rose-50 p-3 text-xs font-semibold text-rose-700">
              <AlertCircle size={16} className="mt-0.5 shrink-0 text-rose-600" />
              <span>{error}</span>
            </div>
          )}

          {successMsg && (
            <div className="flex items-center gap-2.5 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-xs font-semibold text-emerald-700">
              <CheckCircle2 size={16} className="shrink-0 text-emerald-600" />
              <span>{successMsg}</span>
            </div>
          )}

          {/* Amount Input */}
          <div>
            <label
              htmlFor={`${formId}-amount`}
              className="mb-1.5 block text-xs font-bold uppercase tracking-wider text-slate-600"
            >
              Amount to {isCredit ? "Credit" : "Debit"}
            </label>
            <div
              className={`flex items-center rounded-xl border px-3.5 py-2.5 transition focus-within:ring-2 ${
                isOverdraft
                  ? "border-rose-400 bg-rose-50/30 focus-within:ring-rose-200"
                  : "border-slate-200 bg-white focus-within:border-blue-500 focus-within:ring-blue-100"
              }`}
            >
              <span
                className={`text-xl font-black ${
                  isCredit ? "text-emerald-600" : "text-rose-600"
                }`}
              >
                $
              </span>
              <input
                id={`${formId}-amount`}
                type="number"
                min="0.01"
                step="0.01"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="0.00"
                className="w-full bg-transparent px-2.5 text-xl font-extrabold text-slate-900 outline-none placeholder:text-slate-300"
                required
                autoFocus
              />
              <span className="text-xs font-bold text-slate-400">USD</span>
            </div>

            {/* Quick Pills */}
            <div className="mt-2 flex flex-wrap gap-1.5">
              {quickAmounts.map((val) => (
                <button
                  key={val}
                  type="button"
                  onClick={() => setAmount(String(val))}
                  className="rounded-lg border border-slate-200 bg-slate-50 px-2.5 py-1 text-xs font-semibold text-slate-600 transition hover:border-slate-300 hover:bg-slate-100"
                >
                  +${val}
                </button>
              ))}
            </div>
          </div>

          {/* Real-time Projected Balance Preview */}
          <div className="rounded-xl border border-slate-200 bg-slate-50 p-3.5">
            <div className="flex items-center justify-between text-xs">
              <div>
                <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                  Current
                </p>
                <p className="font-semibold text-slate-700">
                  ${currentBalance.toFixed(2)}
                </p>
              </div>

              <div className="flex flex-col items-center">
                <span
                  className={`text-[11px] font-bold ${
                    isCredit ? "text-emerald-600" : "text-rose-600"
                  }`}
                >
                  {isCredit ? `+ $${numAmount.toFixed(2)}` : `- $${numAmount.toFixed(2)}`}
                </span>
                <ArrowRight size={14} className="text-slate-400" />
              </div>

              <div className="text-right">
                <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                  New Balance
                </p>
                <p
                  className={`text-sm font-extrabold ${
                    isOverdraft
                      ? "text-rose-600 line-through"
                      : isCredit
                      ? "text-emerald-700"
                      : "text-slate-900"
                  }`}
                >
                  ${newBalance.toFixed(2)}
                </p>
              </div>
            </div>

            {isOverdraft && (
              <p className="mt-2 text-[11px] font-semibold text-rose-600">
                ⚠️ Overdraft prevented: Debit amount exceeds available balance.
              </p>
            )}
          </div>

          {/* Description / Reason */}
          <div>
            <label
              htmlFor={`${formId}-description`}
              className="mb-1.5 block text-xs font-bold uppercase tracking-wider text-slate-600"
            >
              Reason / Memo
            </label>
            <input
              id={`${formId}-description`}
              type="text"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="e.g. Cash Deposit Correction, Dispute Refund"
              className="w-full rounded-xl border border-slate-200 bg-white px-3.5 py-2.5 text-xs font-medium text-slate-800 outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
            />

            {/* Presets */}
            <div className="mt-1.5 flex flex-wrap gap-1">
              {(isCredit ? creditPresets : debitPresets).map((preset) => (
                <button
                  key={preset}
                  type="button"
                  onClick={() => handleQuickPreset(preset)}
                  className="rounded-md bg-slate-100 px-2 py-0.5 text-[10px] font-semibold text-slate-600 transition hover:bg-slate-200"
                >
                  {preset}
                </button>
              ))}
            </div>
          </div>

          {/* Reference / Ticket ID */}
          <div>
            <label
              htmlFor={`${formId}-reference`}
              className="mb-1.5 block text-xs font-bold uppercase tracking-wider text-slate-600"
            >
              Reference / Case ID <span className="text-slate-400 font-normal">(Optional)</span>
            </label>
            <input
              id={`${formId}-reference`}
              type="text"
              value={reference}
              onChange={(e) => setReference(e.target.value)}
              placeholder="e.g. TICKET-9042, AUDIT-01"
              className="w-full rounded-xl border border-slate-200 bg-white px-3.5 py-2 text-xs font-medium text-slate-800 outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
            />
          </div>

          {/* Actions */}
          <div className="flex items-center gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              disabled={loading}
              className="w-1/3 rounded-xl border border-slate-200 py-3 text-xs font-bold text-slate-600 transition hover:bg-slate-50 disabled:opacity-50"
            >
              Cancel
            </button>

            <button
              type="submit"
              disabled={loading || isOverdraft || !numAmount || numAmount <= 0}
              className={`flex w-2/3 items-center justify-center gap-2 rounded-xl py-3 text-xs font-bold text-white shadow-md transition disabled:cursor-not-allowed disabled:opacity-50 ${
                isCredit
                  ? "bg-emerald-600 hover:bg-emerald-700 shadow-emerald-600/20"
                  : "bg-rose-600 hover:bg-rose-700 shadow-rose-600/20"
              }`}
            >
              <ShieldCheck size={16} />
              {loading
                ? "Processing..."
                : isCredit
                ? `Confirm Credit of $${numAmount.toFixed(2)}`
                : `Confirm Debit of $${numAmount.toFixed(2)}`}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
