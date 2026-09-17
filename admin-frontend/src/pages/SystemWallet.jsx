import {
  useEffect,
  useState,
} from "react";

import {
  ArrowDownToLine,
  ArrowUpFromLine,
  Plus,
  Wallet,
  X,
} from "lucide-react";

import Sidebar from "../components/Sidebar";

import {
  fundSystemWallet,
  getSystemWallet,
  getSystemWalletHistory,
} from "../api/adminApi";


export default function SystemWallet() {
  const [wallet, setWallet] =
    useState({
      balance: 0,
      currency: "USD",
    });

  const [history, setHistory] =
    useState([]);

  const [loading, setLoading] =
    useState(true);

  const [error, setError] =
    useState("");

  const [
    showFundModal,
    setShowFundModal,
  ] = useState(false);

  const [amount, setAmount] =
    useState("");

  const [
    description,
    setDescription,
  ] = useState("");

  const [
    submitting,
    setSubmitting,
  ] = useState(false);


  // =====================================================
  // LOAD
  // =====================================================

  useEffect(() => {
    loadWalletData();
  }, []);


  async function loadWalletData() {
    try {
      setLoading(true);
      setError("");

      const [
        walletResponse,
        historyResponse,
      ] = await Promise.all([
        getSystemWallet(),
        getSystemWalletHistory(),
      ]);

      setWallet(
        walletResponse?.data || {
          balance: 0,
          currency: "USD",
        }
      );

      setHistory(
        historyResponse?.data || []
      );

    } catch (error) {
      console.error(
        "SYSTEM WALLET ERROR:",
        error
      );

      const detail =
        error.response?.data?.detail;

      setError(
        typeof detail === "string"
          ? detail
          : "Unable to load System Wallet"
      );

    } finally {
      setLoading(false);
    }
  }


  // =====================================================
  // MODAL
  // =====================================================

  function openFundModal() {
    setAmount("");
    setDescription("");

    setShowFundModal(true);
  }


  function closeFundModal() {
    if (submitting) {
      return;
    }

    setShowFundModal(false);

    setAmount("");
    setDescription("");
  }


  // =====================================================
  // ADD MONEY
  // =====================================================

  async function handleFund(
    event
  ) {
    event.preventDefault();

    const value =
      Number(amount);

    if (
      !Number.isFinite(value) ||
      value <= 0
    ) {
      alert(
        "Please enter a valid amount"
      );

      return;
    }

    if (
      value > 1000000
    ) {
      alert(
        "Maximum amount is $1,000,000"
      );

      return;
    }

    const confirmed =
      window.confirm(
        `Add $${value.toFixed(
          2
        )} to System Wallet?`
      );

    if (!confirmed) {
      return;
    }

    try {
      setSubmitting(true);

      await fundSystemWallet(
        value,
        description.trim() ||
          "Admin system funding"
      );

      setShowFundModal(false);

      setAmount("");
      setDescription("");

      await loadWalletData();

      alert(
        "System Wallet funded successfully"
      );

    } catch (error) {
      console.error(
        "FUND ERROR:",
        error
      );

      const detail =
        error.response?.data?.detail;

      alert(
        typeof detail === "string"
          ? detail
          : "Unable to fund System Wallet"
      );

    } finally {
      setSubmitting(false);
    }
  }


  // =====================================================
  // HELPERS
  // =====================================================

  function formatDate(
    value
  ) {
    if (!value) {
      return "-";
    }

    const date =
      new Date(value);

    if (
      Number.isNaN(
        date.getTime()
      )
    ) {
      return "-";
    }

    return date.toLocaleString();
  }


  function typeLabel(
    type
  ) {
    if (
      type === "system_funding"
    ) {
      return "System Funding";
    }

    if (
      type === "agent_topup"
    ) {
      return "Agent Top Up";
    }

    return type || "-";
  }


  // =====================================================
  // UI
  // =====================================================

  return (
    <div className="min-h-screen bg-slate-50">

      <Sidebar />


      <main className="ml-[255px] min-h-screen p-8">

        {/* HEADER */}

        <div className="mb-8 flex items-center justify-between gap-5">

          <div>

            <h1 className="text-3xl font-bold tracking-tight text-slate-900">
              System Wallet
            </h1>

            <p className="mt-1 text-sm text-slate-500">
              Manage KhmerPay system
              balance and agent funding
            </p>

          </div>


          <button
            type="button"
            onClick={
              openFundModal
            }
            className="inline-flex items-center gap-2 rounded-xl bg-blue-600 px-5 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-700"
          >
            <Plus size={19} />

            Add Money
          </button>

        </div>


        {/* ERROR */}

        {error && (

          <div className="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {error}
          </div>

        )}


        {loading ? (

          <div className="flex min-h-[320px] items-center justify-center rounded-2xl border border-slate-200 bg-white shadow-sm">

            <div className="text-center">

              <div className="mx-auto h-8 w-8 animate-spin rounded-full border-4 border-slate-200 border-t-blue-600" />

              <p className="mt-4 text-sm text-slate-500">
                Loading System Wallet...
              </p>

            </div>

          </div>

        ) : (

          <>

            {/* ============================================
                SYSTEM BALANCE
            ============================================ */}

            <div className="mb-7 overflow-hidden rounded-3xl bg-gradient-to-br from-blue-600 via-blue-600 to-indigo-700 p-7 text-white shadow-lg shadow-blue-600/10">

              <div className="flex items-center justify-between gap-6">

                <div className="flex items-center gap-5">

                  <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl bg-white/15">
                    <Wallet size={31} />
                  </div>


                  <div>

                    <p className="text-sm font-medium text-blue-100">
                      Available System Balance
                    </p>

                    <h2 className="mt-1 text-4xl font-bold tracking-tight">
                      $
                      {Number(
                        wallet.balance ||
                          0
                      ).toLocaleString(
                        undefined,
                        {
                          minimumFractionDigits:
                            2,

                          maximumFractionDigits:
                            2,
                        }
                      )}
                    </h2>

                    <p className="mt-1 text-sm text-blue-100">
                      {wallet.currency ||
                        "USD"}
                    </p>

                  </div>

                </div>


                <div className="hidden rounded-2xl bg-white/10 px-6 py-4 text-right lg:block">

                  <p className="text-xs text-blue-100">
                    Wallet Purpose
                  </p>

                  <p className="mt-1 font-semibold">
                    Agent Float Funding
                  </p>

                </div>

              </div>

            </div>


            {/* ============================================
                FLOW
            ============================================ */}

            <div className="mb-7 grid grid-cols-1 gap-4 lg:grid-cols-3">

              {/* STEP 1 */}

              <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">

                <div className="mb-4 flex h-11 w-11 items-center justify-center rounded-xl bg-blue-50 text-blue-600">
                  <Plus size={21} />
                </div>

                <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                  Step 1
                </p>

                <h3 className="mt-1 font-semibold text-slate-900">
                  Admin Funding
                </h3>

                <p className="mt-1 text-sm leading-6 text-slate-500">
                  Add money to the
                  KhmerPay System Wallet.
                </p>

              </div>


              {/* STEP 2 */}

              <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">

                <div className="mb-4 flex h-11 w-11 items-center justify-center rounded-xl bg-amber-50 text-amber-600">
                  <ArrowUpFromLine
                    size={21}
                  />
                </div>

                <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                  Step 2
                </p>

                <h3 className="mt-1 font-semibold text-slate-900">
                  Agent Top Up
                </h3>

                <p className="mt-1 text-sm leading-6 text-slate-500">
                  Transfer money from the
                  System Wallet to an Agent.
                </p>

              </div>


              {/* STEP 3 */}

              <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">

                <div className="mb-4 flex h-11 w-11 items-center justify-center rounded-xl bg-green-50 text-green-600">
                  <ArrowDownToLine
                    size={21}
                  />
                </div>

                <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                  Step 3
                </p>

                <h3 className="mt-1 font-semibold text-slate-900">
                  Customer Deposit
                </h3>

                <p className="mt-1 text-sm leading-6 text-slate-500">
                  Agent transfers balance
                  to a verified customer.
                </p>

              </div>

            </div>


            {/* ============================================
                HISTORY
            ============================================ */}

            <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">

              <div className="flex items-center justify-between gap-5 border-b border-slate-100 px-6 py-5">

                <div>

                  <h2 className="text-xl font-bold text-slate-900">
                    Wallet History
                  </h2>

                  <p className="mt-1 text-sm text-slate-500">
                    System funding and
                    Agent top-up transactions
                  </p>

                </div>


                <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                  {history.length}{" "}
                  {history.length === 1
                    ? "record"
                    : "records"}
                </span>

              </div>


              {history.length === 0 ? (

                <div className="flex min-h-[230px] flex-col items-center justify-center p-8 text-center">

                  <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-slate-100 text-slate-400">
                    <Wallet size={25} />
                  </div>

                  <h3 className="font-semibold text-slate-800">
                    No wallet transactions
                  </h3>

                  <p className="mt-1 max-w-sm text-sm text-slate-500">
                    Click Add Money to fund
                    your System Wallet.
                  </p>

                </div>

              ) : (

                <div className="overflow-x-auto">

                  <table className="w-full border-collapse">

                    <thead className="bg-slate-50">

                      <tr className="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">

                        <th className="whitespace-nowrap px-6 py-4">
                          Transaction
                        </th>

                        <th className="whitespace-nowrap px-6 py-4">
                          Type
                        </th>

                        <th className="whitespace-nowrap px-6 py-4">
                          Agent
                        </th>

                        <th className="whitespace-nowrap px-6 py-4">
                          Amount
                        </th>

                        <th className="whitespace-nowrap px-6 py-4">
                          Description
                        </th>

                        <th className="whitespace-nowrap px-6 py-4">
                          Date
                        </th>

                      </tr>

                    </thead>


                    <tbody className="divide-y divide-slate-100">

                      {history.map(
                        (item) => (

                          <tr
                            key={
                              item.id ||
                              item.transaction_id
                            }
                            className="transition hover:bg-slate-50"
                          >

                            <td className="whitespace-nowrap px-6 py-4 text-sm font-semibold text-slate-800">
                              {
                                item.transaction_id
                              }
                            </td>


                            <td className="whitespace-nowrap px-6 py-4">

                              <span
                                className={
                                  item.type ===
                                  "system_funding"
                                    ? "inline-flex rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700"
                                    : "inline-flex rounded-full bg-green-50 px-3 py-1 text-xs font-semibold text-green-700"
                                }
                              >
                                {typeLabel(
                                  item.type
                                )}
                              </span>

                            </td>


                            <td className="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                              {item.agent_name ||
                                "-"}
                            </td>


                            <td className="whitespace-nowrap px-6 py-4 text-sm font-bold text-slate-900">
                              $
                              {Number(
                                item.amount ||
                                  0
                              ).toLocaleString(
                                undefined,
                                {
                                  minimumFractionDigits:
                                    2,

                                  maximumFractionDigits:
                                    2,
                                }
                              )}
                            </td>


                            <td className="min-w-[220px] px-6 py-4 text-sm text-slate-600">
                              {item.description ||
                                "-"}
                            </td>


                            <td className="whitespace-nowrap px-6 py-4 text-sm text-slate-500">
                              {formatDate(
                                item.created_at
                              )}
                            </td>

                          </tr>

                        )
                      )}

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

          <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">

            <div className="w-full max-w-md rounded-3xl bg-white p-7 shadow-2xl">

              <div className="mb-6 flex items-start justify-between gap-5">

                <div>

                  <h2 className="text-2xl font-bold text-slate-900">
                    Add Money
                  </h2>

                  <p className="mt-1 text-sm text-slate-500">
                    Fund KhmerPay
                    System Wallet
                  </p>

                </div>


                <button
                  type="button"
                  onClick={
                    closeFundModal
                  }
                  disabled={
                    submitting
                  }
                  className="rounded-xl bg-slate-100 p-2 text-slate-600 transition hover:bg-slate-200 disabled:opacity-50"
                >
                  <X size={20} />
                </button>

              </div>


              {/* CURRENT BALANCE */}

              <div className="mb-5 rounded-2xl bg-blue-50 p-4">

                <p className="text-xs font-semibold uppercase tracking-wide text-blue-600">
                  Current System Balance
                </p>

                <p className="mt-1 text-2xl font-bold text-blue-700">
                  $
                  {Number(
                    wallet.balance ||
                      0
                  ).toLocaleString(
                    undefined,
                    {
                      minimumFractionDigits:
                        2,

                      maximumFractionDigits:
                        2,
                    }
                  )}
                </p>

              </div>


              <form
                onSubmit={
                  handleFund
                }
              >

                {/* AMOUNT */}

                <label className="mb-2 block text-sm font-semibold text-slate-700">
                  Amount
                </label>


                <div className="flex items-center rounded-xl border border-slate-200 px-4 transition focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">

                  <span className="text-xl font-bold text-slate-400">
                    $
                  </span>

                  <input
                    type="number"
                    min="0.01"
                    max="1000000"
                    step="0.01"
                    value={amount}
                    onChange={(event) =>
                      setAmount(
                        event.target.value
                      )
                    }
                    placeholder="0.00"
                    className="w-full bg-transparent px-3 py-3 text-xl font-bold text-slate-900 outline-none"
                    required
                  />

                </div>


                {/* QUICK AMOUNTS */}

                <div className="mt-3 grid grid-cols-4 gap-2">

                  {[
                    1000,
                    5000,
                    10000,
                    50000,
                  ].map(
                    (value) => (

                      <button
                        key={value}
                        type="button"
                        onClick={() =>
                          setAmount(
                            String(value)
                          )
                        }
                        className="rounded-xl border border-slate-200 py-2 text-sm font-semibold text-slate-600 transition hover:border-blue-500 hover:bg-blue-50 hover:text-blue-600"
                      >
                        $
                        {value >= 1000
                          ? `${
                              value /
                              1000
                            }K`
                          : value}
                      </button>

                    )
                  )}

                </div>


                {/* DESCRIPTION */}

                <label className="mb-2 mt-5 block text-sm font-semibold text-slate-700">
                  Description
                </label>


                <input
                  type="text"
                  value={description}
                  onChange={(event) =>
                    setDescription(
                      event.target.value
                    )
                  }
                  placeholder="Example: Initial system funding"
                  className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                />


                <div className="mt-5 rounded-xl border border-amber-200 bg-amber-50 p-3">

                  <p className="text-xs leading-5 text-amber-700">
                    For your demo project,
                    this increases the System
                    Wallet balance. The System
                    Wallet can then fund Agent
                    wallets.
                  </p>

                </div>


                <button
                  type="submit"
                  disabled={
                    submitting
                  }
                  className="mt-6 w-full rounded-xl bg-blue-600 py-3.5 text-sm font-semibold text-white transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {submitting
                    ? "Processing..."
                    : "Confirm Funding"}
                </button>

              </form>

            </div>

          </div>
        )}

      </main>

    </div>
  );
}