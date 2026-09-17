import {
  useEffect,
  useState,
} from "react";

import {
  CalendarDays,
  CheckCircle2,
  History,
  Phone,
  ReceiptText,
  RefreshCcw,
  UserRound,
  Wallet,
} from "lucide-react";

import Sidebar
  from "../components/Sidebar";

import {
  getAgentTransactions,
} from "../api/agentApi";


export default function AgentHistory() {
  const [
    transactions,
    setTransactions,
  ] = useState([]);

  const [
    loading,
    setLoading,
  ] = useState(true);

  const [
    error,
    setError,
  ] = useState("");


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

      const response =
        await getAgentTransactions();

      setTransactions(
        response?.data ||
        []
      );

    } catch (error) {
      console.error(
        "AGENT HISTORY ERROR:",
        error
      );

      const detail =
        error.response?.data
          ?.detail;

      setError(
        typeof detail ===
        "string"
          ? detail
          : detail?.message ||
            "Unable to load transactions"
      );

    } finally {
      setLoading(false);
    }
  }


  // =====================================================
  // TOTAL DEPOSIT
  // =====================================================

  const totalDeposit =
    transactions.reduce(
      (
        total,
        item
      ) =>
        total +
        Number(
          item.amount ||
          0
        ),
      0
    );


  return (
    <div className="min-h-screen bg-slate-50">

      <Sidebar />


      <main className="ml-[255px] min-h-screen p-8">

        {/* HEADER */}

        <div className="mb-8 flex flex-wrap items-center justify-between gap-4">

          <div>

            <div className="flex items-center gap-3">

              <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-blue-50 text-blue-600">

                <History
                  size={23}
                />

              </div>


              <div>

                <h1 className="text-3xl font-bold tracking-tight text-slate-900">
                  Deposit History
                </h1>


                <p className="mt-1 text-sm text-slate-500">
                  View your customer deposit transactions
                </p>

              </div>

            </div>

          </div>


          <button
            type="button"
            onClick={
              loadTransactions
            }
            disabled={
              loading
            }
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
          >

            <RefreshCcw
              size={17}
              className={
                loading
                  ? "animate-spin"
                  : ""
              }
            />

            Refresh

          </button>

        </div>


        {/* SUMMARY CARDS */}

        <div className="mb-6 grid gap-4 md:grid-cols-2">

          <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">

            <div className="flex items-center gap-4">

              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 text-blue-600">

                <ReceiptText
                  size={24}
                />

              </div>


              <div>

                <p className="text-sm text-slate-500">
                  Total Transactions
                </p>


                <h2 className="mt-1 text-2xl font-bold text-slate-900">
                  {
                    transactions.length
                  }
                </h2>

              </div>

            </div>

          </div>


          <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">

            <div className="flex items-center gap-4">

              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-green-50 text-green-600">

                <Wallet
                  size={24}
                />

              </div>


              <div>

                <p className="text-sm text-slate-500">
                  Total Deposited
                </p>


                <h2 className="mt-1 text-2xl font-bold text-slate-900">

                  $

                  {totalDeposit.toLocaleString(
                    undefined,
                    {
                      minimumFractionDigits:
                        2,

                      maximumFractionDigits:
                        2,
                    }
                  )}

                </h2>

              </div>

            </div>

          </div>

        </div>


        {/* ERROR */}

        {error && (

          <div className="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {error}
          </div>

        )}


        {/* TABLE */}

        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">

          <div className="border-b border-slate-100 px-6 py-5">

            <h2 className="text-lg font-bold text-slate-900">
              Transactions
            </h2>


            <p className="mt-1 text-sm text-slate-500">
              Your latest successful customer deposits
            </p>

          </div>


          {loading ? (

            <div className="flex min-h-[260px] items-center justify-center">

              <div className="text-center">

                <RefreshCcw
                  size={28}
                  className="mx-auto animate-spin text-blue-600"
                />


                <p className="mt-3 text-sm text-slate-500">
                  Loading transactions...
                </p>

              </div>

            </div>

          ) : transactions.length ===
            0 ? (

            <div className="flex min-h-[300px] items-center justify-center px-6">

              <div className="text-center">

                <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-slate-400">

                  <ReceiptText
                    size={30}
                  />

                </div>


                <h3 className="mt-4 font-bold text-slate-900">
                  No transactions yet
                </h3>


                <p className="mt-1 text-sm text-slate-500">
                  Customer deposits will appear here.
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

                  {transactions.map(
                    (
                      item
                    ) => (

                      <tr
                        key={
                          item.id ||
                          item.transaction_id
                        }
                        className="transition hover:bg-slate-50/70"
                      >

                        {/* TRANSACTION */}

                        <td className="px-6 py-5">

                          <div className="flex items-center gap-3">

                            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600">

                              <ReceiptText
                                size={18}
                              />

                            </div>


                            <div>

                              <p className="font-semibold text-slate-900">
                                {
                                  item.transaction_id ||
                                  "-"
                                }
                              </p>


                              <p className="mt-0.5 text-xs text-slate-400">
                                Cash Deposit
                              </p>

                            </div>

                          </div>

                        </td>


                        {/* CUSTOMER */}

                        <td className="px-6 py-5">

                          <div className="flex items-center gap-2">

                            <UserRound
                              size={17}
                              className="text-slate-400"
                            />


                            <span className="font-medium text-slate-800">
                              {
                                item.customer_name ||
                                "-"
                              }
                            </span>

                          </div>

                        </td>


                        {/* PHONE */}

                        <td className="px-6 py-5">

                          <div className="flex items-center gap-2 text-sm text-slate-600">

                            <Phone
                              size={16}
                              className="text-slate-400"
                            />

                            {
                              item.customer_phone ||
                              "-"
                            }

                          </div>

                        </td>


                        {/* AMOUNT */}

                        <td className="px-6 py-5">

                          <span className="font-bold text-slate-900">

                            $

                            {Number(
                              item.amount ||
                              0
                            ).toFixed(
                              2
                            )}

                          </span>

                        </td>


                        {/* NEW BALANCE */}

                        <td className="px-6 py-5">

                          <span className="font-semibold text-blue-600">

                            $

                            {Number(
                              item.balance_after ||
                              0
                            ).toFixed(
                              2
                            )}

                          </span>

                        </td>


                        {/* STATUS */}

                        <td className="px-6 py-5">

                          <span className="inline-flex items-center gap-1.5 rounded-full bg-green-50 px-3 py-1.5 text-xs font-semibold capitalize text-green-700">

                            <CheckCircle2
                              size={14}
                            />

                            {
                              item.status ||
                              "success"
                            }

                          </span>

                        </td>


                        {/* DATE */}

                        <td className="px-6 py-5">

                          <div className="flex items-center gap-2 text-sm text-slate-500">

                            <CalendarDays
                              size={16}
                              className="text-slate-400"
                            />

                            {item.created_at
                              ? new Date(
                                  item.created_at
                                ).toLocaleString()
                              : "-"}

                          </div>

                        </td>

                      </tr>

                    )
                  )}

                </tbody>

              </table>

            </div>

          )}

        </div>

      </main>

    </div>
  );
}