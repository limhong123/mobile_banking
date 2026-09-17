import {
  useEffect,
  useState,
} from "react";

import {
  Banknote,
  CircleDollarSign,
  ReceiptText,
  RefreshCw,
  Wallet,
} from "lucide-react";

import Sidebar from "../components/Sidebar";

import {
  getAgentDashboard,
} from "../api/agentApi";


export default function AgentDashboard() {
  const [
    data,
    setData,
  ] = useState(null);

  const [
    loading,
    setLoading,
  ] = useState(true);

  const [
    refreshing,
    setRefreshing,
  ] = useState(false);

  const [
    error,
    setError,
  ] = useState("");


  // =====================================================
  // LOAD DASHBOARD
  // =====================================================

  useEffect(() => {
    loadDashboard();
  }, []);


  async function loadDashboard(
    refresh = false
  ) {
    try {
      setError("");

      if (refresh) {
        setRefreshing(true);
      } else {
        setLoading(true);
      }


      const response =
        await getAgentDashboard();


      setData(
        response?.data ||
        {}
      );

    } catch (error) {
      console.error(
        "AGENT DASHBOARD ERROR:",
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
            "Unable to load dashboard."
      );

    } finally {
      setLoading(false);

      setRefreshing(false);
    }
  }


  // =====================================================
  // VALUES
  // =====================================================

  const walletBalance =
    Number(
      data?.wallet_balance ??
      data?.balance ??
      0
    );


  const totalTransactions =
    Number(
      data?.total_transactions ??
      0
    );


  const totalDeposits =
    Number(
      data?.total_deposit_amount ??
      data?.total_deposit ??
      0
    );


  const recentTransactions =
    Array.isArray(
      data?.recent_transactions
    )
      ? data.recent_transactions
      : [];


  // =====================================================
  // UI
  // =====================================================

  return (
    <div className="min-h-screen bg-slate-50">

      <Sidebar />


      <main className="ml-[255px] min-h-screen p-8">

        {/* =================================================
            HEADER
        ================================================= */}

        <div className="mb-8 flex flex-wrap items-center justify-between gap-4">

          <div>

            <h1 className="text-3xl font-bold tracking-tight text-slate-900">
              Agent Dashboard
            </h1>

            <p className="mt-1 text-sm text-slate-500">
              KhmerPay deposit and
              wallet overview
            </p>

          </div>


          <button
            type="button"
            disabled={
              refreshing
            }
            onClick={() =>
              loadDashboard(
                true
              )
            }
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
          >

            <RefreshCw
              size={17}
              className={
                refreshing
                  ? "animate-spin"
                  : ""
              }
            />

            {refreshing
              ? "Refreshing..."
              : "Refresh"}

          </button>

        </div>


        {/* =================================================
            ERROR
        ================================================= */}

        {error && (

          <div className="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">

            {error}

          </div>

        )}


        {/* =================================================
            LOADING
        ================================================= */}

        {loading ? (

          <div className="flex min-h-[400px] items-center justify-center">

            <div className="text-center">

              <div className="mx-auto h-9 w-9 animate-spin rounded-full border-4 border-slate-200 border-t-blue-600" />

              <p className="mt-4 text-sm text-slate-500">
                Loading dashboard...
              </p>

            </div>

          </div>

        ) : (

          <>

            {/* =============================================
                STATS
            ============================================= */}

            <div className="mb-8 grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-3">


              {/* AGENT WALLET */}

              <StatCard
                title="Wallet Balance"
                value={
                  `$${walletBalance.toLocaleString(
                    undefined,
                    {
                      minimumFractionDigits:
                        2,

                      maximumFractionDigits:
                        2,
                    }
                  )}`
                }
                description="Available for customer deposits"
                icon={Wallet}
              />


              {/* TRANSACTIONS */}

              <StatCard
                title="Total Transactions"
                value={
                  totalTransactions
                    .toLocaleString()
                }
                description="Successful deposit transactions"
                icon={ReceiptText}
              />


              {/* TOTAL DEPOSIT */}

              <StatCard
                title="Total Deposits"
                value={
                  `$${totalDeposits.toLocaleString(
                    undefined,
                    {
                      minimumFractionDigits:
                        2,

                      maximumFractionDigits:
                        2,
                    }
                  )}`
                }
                description="Total money deposited to customers"
                icon={Banknote}
              />

            </div>


            {/* =============================================
                WALLET INFO
            ============================================= */}

            <div className="mb-8 overflow-hidden rounded-2xl bg-gradient-to-br from-blue-700 to-blue-500 p-6 text-white shadow-lg shadow-blue-200">

              <div className="flex flex-wrap items-center justify-between gap-5">

                <div>

                  <p className="text-sm font-medium text-blue-100">
                    Available Agent Balance
                  </p>


                  <h2 className="mt-2 text-4xl font-bold tracking-tight">

                    $

                    {walletBalance.toLocaleString(
                      undefined,
                      {
                        minimumFractionDigits:
                          2,

                        maximumFractionDigits:
                          2,
                      }
                    )}

                  </h2>


                  <p className="mt-3 max-w-lg text-sm leading-6 text-blue-100">
                    This balance is funded by
                    KhmerPay Admin and can be
                    used to deposit money into
                    customer accounts.
                  </p>

                </div>


                <div className="flex h-20 w-20 items-center justify-center rounded-2xl bg-white/15">

                  <CircleDollarSign
                    size={40}
                  />

                </div>

              </div>

            </div>


            {/* =============================================
                RECENT TRANSACTIONS
            ============================================= */}

            <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">

              {/* HEADER */}

              <div className="border-b border-slate-100 px-6 py-5">

                <h2 className="text-lg font-bold text-slate-900">
                  Recent Deposits
                </h2>

                <p className="mt-1 text-sm text-slate-500">
                  Your latest customer
                  deposit transactions
                </p>

              </div>


              {/* EMPTY */}

              {recentTransactions.length ===
              0 ? (

                <div className="flex min-h-[280px] flex-col items-center justify-center p-8 text-center">

                  <div className="flex h-14 w-14 items-center justify-center rounded-full bg-slate-100 text-slate-400">

                    <ReceiptText
                      size={26}
                    />

                  </div>


                  <h3 className="mt-4 font-semibold text-slate-800">
                    No deposits yet
                  </h3>


                  <p className="mt-1 text-sm text-slate-500">
                    Your recent customer
                    deposits will appear here.
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
                          Customer
                        </th>

                        <th className="whitespace-nowrap px-6 py-4">
                          Phone
                        </th>

                        <th className="whitespace-nowrap px-6 py-4">
                          Amount
                        </th>

                        <th className="whitespace-nowrap px-6 py-4">
                          Status
                        </th>

                        <th className="whitespace-nowrap px-6 py-4">
                          Date
                        </th>

                      </tr>

                    </thead>


                    <tbody className="divide-y divide-slate-100">

                      {recentTransactions.map(
                        (
                          item,
                          index
                        ) => (

                          <tr
                            key={
                              item.transaction_id ||
                              item.id ||
                              index
                            }
                            className="transition hover:bg-slate-50"
                          >

                            {/* TRANSACTION */}

                            <td className="whitespace-nowrap px-6 py-5">

                              <p className="font-mono text-xs font-semibold text-slate-700">

                                {item.transaction_id ||
                                  "-"}

                              </p>

                            </td>


                            {/* CUSTOMER */}

                            <td className="whitespace-nowrap px-6 py-5">

                              <div className="flex items-center gap-3">

                                <div className="flex h-9 w-9 items-center justify-center rounded-full bg-blue-50 text-sm font-bold text-blue-600">

                                  {item.customer_name
                                    ?.charAt(0)
                                    .toUpperCase() ||
                                    "C"}

                                </div>


                                <span className="font-semibold text-slate-900">

                                  {item.customer_name ||
                                    "Customer"}

                                </span>

                              </div>

                            </td>


                            {/* PHONE */}

                            <td className="whitespace-nowrap px-6 py-5 text-sm text-slate-600">

                              {item.customer_phone ||
                                item.phone_number ||
                                "-"}

                            </td>


                            {/* AMOUNT */}

                            <td className="whitespace-nowrap px-6 py-5">

                              <span className="font-bold text-slate-900">

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

                              </span>

                            </td>


                            {/* STATUS */}

                            <td className="whitespace-nowrap px-6 py-5">

                              <TransactionStatus
                                status={
                                  item.status
                                }
                              />

                            </td>


                            {/* DATE */}

                            <td className="whitespace-nowrap px-6 py-5 text-sm text-slate-500">

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

      </main>

    </div>
  );
}


// =====================================================
// STAT CARD
// =====================================================

function StatCard({
  title,
  value,
  description,
  icon: Icon,
}) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">

      <div className="mb-5 flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 text-blue-600">

        <Icon
          size={23}
        />

      </div>


      <p className="text-sm font-medium text-slate-500">
        {title}
      </p>


      <h2 className="mt-1 text-3xl font-bold tracking-tight text-slate-900">
        {value}
      </h2>


      <p className="mt-2 text-xs leading-5 text-slate-400">
        {description}
      </p>

    </div>
  );
}


// =====================================================
// TRANSACTION STATUS
// =====================================================

function TransactionStatus({
  status,
}) {
  const value =
    status
      ?.toString()
      .toLowerCase() ||
    "unknown";


  if (
    value === "success" ||
    value === "completed"
  ) {
    return (
      <span className="inline-flex rounded-full bg-green-50 px-3 py-1 text-xs font-semibold capitalize text-green-700">

        {value}

      </span>
    );
  }


  if (
    value === "failed" ||
    value === "rejected"
  ) {
    return (
      <span className="inline-flex rounded-full bg-red-50 px-3 py-1 text-xs font-semibold capitalize text-red-700">

        {value}

      </span>
    );
  }


  if (
    value === "pending"
  ) {
    return (
      <span className="inline-flex rounded-full bg-amber-50 px-3 py-1 text-xs font-semibold capitalize text-amber-700">

        {value}

      </span>
    );
  }


  return (
    <span className="inline-flex rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold capitalize text-slate-600">

      {value}

    </span>
  );
}


// =====================================================
// DATE FORMAT
// =====================================================

function formatDate(
  value
) {
  if (!value) {
    return "-";
  }


  const date =
    new Date(
      value
    );


  if (
    Number.isNaN(
      date.getTime()
    )
  ) {
    return "-";
  }


  return date.toLocaleString();
}