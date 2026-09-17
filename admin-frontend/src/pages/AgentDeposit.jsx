import {
  useState,
} from "react";

import {
  BadgeCheck,
  Banknote,
  CheckCircle2,
  Search,
  UserRound,
} from "lucide-react";

import Sidebar
  from "../components/Sidebar";

import {
  depositCustomer,
  searchCustomer,
} from "../api/agentApi";


export default function AgentDeposit() {
  const [
    phoneNumber,
    setPhoneNumber,
  ] = useState("");

  const [
    customer,
    setCustomer,
  ] = useState(null);

  const [
    amount,
    setAmount,
  ] = useState("");

  const [
    searching,
    setSearching,
  ] = useState(false);

  const [
    depositing,
    setDepositing,
  ] = useState(false);

  const [
    success,
    setSuccess,
  ] = useState(null);

  const [
    error,
    setError,
  ] = useState("");


  const quickAmounts = [
    10,
    20,
    50,
    100,
    200,
    500,
  ];


  // =====================================================
  // SEARCH CUSTOMER
  // =====================================================

  async function handleSearch() {
    const phone =
      phoneNumber.trim();


    if (!phone) {
      setError(
        "Enter customer phone number"
      );

      return;
    }


    try {
      setSearching(true);

      setCustomer(
        null
      );

      setSuccess(
        null
      );

      setError(
        ""
      );


      const response =
        await searchCustomer(
          phone
        );


      setCustomer(
        response?.data ||
        null
      );

    } catch (error) {
      console.error(
        "SEARCH CUSTOMER ERROR:",
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
            "Customer not found"
      );

    } finally {
      setSearching(false);
    }
  }


  // =====================================================
  // DEPOSIT
  // =====================================================

  async function handleDeposit() {
    if (!customer) {
      return;
    }


    const depositAmount =
      Number(
        amount
      );


    if (
      !Number.isFinite(
        depositAmount
      ) ||
      depositAmount <= 0
    ) {
      setError(
        "Enter a valid amount"
      );

      return;
    }


    const confirmed =
      window.confirm(
        `Deposit $${depositAmount.toFixed(
          2
        )} to ${customer.first_name} ${customer.last_name}?`
      );


    if (!confirmed) {
      return;
    }


    try {
      setDepositing(
        true
      );

      setError(
        ""
      );

      setSuccess(
        null
      );


      const response =
        await depositCustomer({
          phoneNumber:
            customer.phone_number,

          amount:
            depositAmount,

          description:
            "Cash deposit by agent",
        });


      const data =
        response?.data ||
        {};


      setSuccess(
        data
      );


      setCustomer(
        (
          previous
        ) => ({
          ...previous,

          balance:
            data.balance_after ??
            previous.balance,
        })
      );


      setAmount(
        ""
      );

    } catch (error) {
      console.error(
        "DEPOSIT ERROR:",
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
            "Deposit failed"
      );

    } finally {
      setDepositing(
        false
      );
    }
  }


  // =====================================================
  // RESET
  // =====================================================

  function resetCustomer() {
    setPhoneNumber(
      ""
    );

    setCustomer(
      null
    );

    setAmount(
      ""
    );

    setSuccess(
      null
    );

    setError(
      ""
    );
  }


  // =====================================================
  // UI
  // =====================================================

  return (
    <div className="min-h-screen bg-slate-50">

      <Sidebar />


      <main className="ml-[255px] min-h-screen p-8">

        {/* HEADER */}

        <div className="mb-8">

          <h1 className="text-3xl font-bold tracking-tight text-slate-900">
            Cash Deposit
          </h1>


          <p className="mt-1 text-sm text-slate-500">
            Deposit money from the Agent Wallet
            to a verified KhmerPay customer
          </p>

        </div>


        {/* ERROR */}

        {error && (

          <div className="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {error}
          </div>

        )}


        <div className="grid gap-6 xl:grid-cols-[1fr_420px]">

          {/* =================================================
              LEFT SIDE
          ================================================= */}

          <div className="space-y-6">

            {/* CUSTOMER SEARCH */}

            <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">

              <div>

                <h2 className="text-xl font-bold text-slate-900">
                  Find Customer
                </h2>


                <p className="mt-1 text-sm text-slate-500">
                  Search using the customer's
                  registered phone number
                </p>

              </div>


              <div className="mt-6">

                <label className="mb-2 block text-sm font-semibold text-slate-700">
                  Customer Phone Number
                </label>


                <div className="flex gap-3">

                  <div className="flex flex-1 items-center rounded-xl border border-slate-200 bg-white px-4 transition focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">

                    <Search
                      size={19}
                      className="shrink-0 text-slate-400"
                    />


                    <input
                      type="text"
                      value={
                        phoneNumber
                      }
                      onChange={(
                        event
                      ) =>
                        setPhoneNumber(
                          event
                            .target
                            .value
                        )
                      }
                      onKeyDown={(
                        event
                      ) => {
                        if (
                          event.key ===
                          "Enter"
                        ) {
                          handleSearch();
                        }
                      }}
                      placeholder="+855 98 494 201"
                      className="w-full bg-transparent px-3 py-3 text-sm text-slate-900 outline-none placeholder:text-slate-400"
                    />

                  </div>


                  <button
                    type="button"
                    disabled={
                      searching
                    }
                    onClick={
                      handleSearch
                    }
                    className="inline-flex min-w-[120px] items-center justify-center gap-2 rounded-xl bg-blue-600 px-5 py-3 text-sm font-semibold text-white transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                  >

                    <Search
                      size={17}
                    />


                    {searching
                      ? "Searching..."
                      : "Search"}

                  </button>

                </div>

              </div>

            </div>


            {/* CUSTOMER INFORMATION */}

            {customer && (

              <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">

                <div className="flex flex-wrap items-start justify-between gap-5">

                  <div className="flex items-center gap-4">

                    <div className="flex h-14 w-14 items-center justify-center rounded-full bg-blue-50 text-blue-600">

                      <UserRound
                        size={27}
                      />

                    </div>


                    <div>

                      <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                        Customer
                      </p>


                      <h2 className="mt-1 text-xl font-bold text-slate-900">

                        {
                          customer.first_name
                        }{" "}
                        {
                          customer.last_name
                        }

                      </h2>


                      <p className="mt-1 text-sm text-slate-500">
                        {
                          customer.phone_number
                        }
                      </p>

                    </div>

                  </div>


                  <span className="inline-flex items-center gap-1.5 rounded-full bg-green-50 px-3 py-1.5 text-xs font-semibold text-green-700">

                    <BadgeCheck
                      size={15}
                    />

                    Verified

                  </span>

                </div>


                <div className="mt-6 grid gap-4 border-t border-slate-100 pt-5 sm:grid-cols-2">

                  <div>

                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                      Current Balance
                    </p>


                    <p className="mt-1 text-2xl font-bold text-slate-900">

                      $

                      {Number(
                        customer.balance ||
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


                  <div>

                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                      KYC Status
                    </p>


                    <p className="mt-1 font-semibold capitalize text-green-700">
                      {
                        customer.kyc_status
                      }
                    </p>

                  </div>

                </div>


                <button
                  type="button"
                  onClick={
                    resetCustomer
                  }
                  className="mt-5 text-sm font-semibold text-blue-600 transition hover:text-blue-700"
                >
                  Search another customer
                </button>

              </div>

            )}


            {/* SUCCESS */}

            {success && (

              <div className="rounded-2xl border border-green-200 bg-green-50 p-6 shadow-sm">

                <div className="flex flex-col items-center text-center">

                  <CheckCircle2
                    size={58}
                    className="text-green-600"
                  />


                  <h2 className="mt-4 text-2xl font-bold text-green-800">
                    Deposit Successful
                  </h2>


                  <p className="mt-3 text-4xl font-bold text-slate-900">

                    $

                    {Number(
                      success.amount ||
                      0
                    ).toFixed(
                      2
                    )}

                  </p>

                </div>


                <div className="mt-6 space-y-3 rounded-xl bg-white p-4">

                  <ReceiptRow
                    label="Customer"
                    value={
                      success.customer_name ||
                      `${customer?.first_name || ""} ${customer?.last_name || ""}`
                    }
                  />


                  <ReceiptRow
                    label="Transaction ID"
                    value={
                      success.transaction_id ||
                      "-"
                    }
                  />


                  <ReceiptRow
                    label="Old Balance"
                    value={`$${Number(
                      success.balance_before ||
                      0
                    ).toFixed(
                      2
                    )}`}
                  />


                  <ReceiptRow
                    label="New Balance"
                    value={`$${Number(
                      success.balance_after ||
                      0
                    ).toFixed(
                      2
                    )}`}
                  />

                </div>

              </div>

            )}

          </div>


          {/* =================================================
              RIGHT SIDE
          ================================================= */}

          <div>

            <div className="sticky top-8 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">

              <div className="flex items-center gap-3">

                <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-green-50 text-green-600">

                  <Banknote
                    size={23}
                  />

                </div>


                <div>

                  <h2 className="font-bold text-slate-900">
                    Deposit Amount
                  </h2>


                  <p className="text-xs text-slate-500">
                    Cash received from customer
                  </p>

                </div>

              </div>


              {!customer ? (

                <div className="mt-8 rounded-xl border border-dashed border-slate-200 bg-slate-50 p-8 text-center">

                  <UserRound
                    size={36}
                    className="mx-auto text-slate-300"
                  />


                  <p className="mt-3 text-sm font-semibold text-slate-600">
                    Search customer first
                  </p>


                  <p className="mt-1 text-xs text-slate-400">
                    Customer verification is required
                    before making a deposit.
                  </p>

                </div>

              ) : (

                <>

                  <div className="mt-6">

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
                        step="0.01"
                        value={
                          amount
                        }
                        onChange={(
                          event
                        ) =>
                          setAmount(
                            event
                              .target
                              .value
                          )
                        }
                        placeholder="0.00"
                        className="w-full bg-transparent px-3 py-4 text-2xl font-bold text-slate-900 outline-none placeholder:text-slate-300"
                      />

                    </div>

                  </div>


                  {/* QUICK AMOUNT */}

                  <div className="mt-3 grid grid-cols-3 gap-2">

                    {quickAmounts.map(
                      (
                        value
                      ) => (

                        <button
                          key={
                            value
                          }
                          type="button"
                          onClick={() =>
                            setAmount(
                              String(
                                value
                              )
                            )
                          }
                          className="rounded-xl border border-slate-200 py-2.5 text-sm font-semibold text-slate-600 transition hover:border-blue-500 hover:bg-blue-50 hover:text-blue-600"
                        >

                          ${value}

                        </button>

                      )
                    )}

                  </div>


                  {/* SUMMARY */}

                  <div className="mt-6 rounded-xl bg-slate-50 p-4">

                    <ReceiptRow
                      label="Customer"
                      value={`${customer.first_name} ${customer.last_name}`}
                    />


                    <div className="my-3 border-t border-slate-200" />


                    <ReceiptRow
                      label="Deposit Amount"
                      value={`$${Number(
                        amount ||
                        0
                      ).toFixed(
                        2
                      )}`}
                    />

                  </div>


                  <div className="mt-5 rounded-xl border border-amber-200 bg-amber-50 p-3">

                    <p className="text-xs leading-5 text-amber-700">
                      This amount will be deducted
                      from your Agent Wallet and added
                      to the customer's wallet.
                    </p>

                  </div>


                  <button
                    type="button"
                    disabled={
                      depositing
                    }
                    onClick={
                      handleDeposit
                    }
                    className="mt-6 w-full rounded-xl bg-green-600 py-3.5 text-sm font-semibold text-white transition hover:bg-green-700 disabled:cursor-not-allowed disabled:opacity-50"
                  >

                    {depositing
                      ? "Processing..."
                      : "Confirm Deposit"}

                  </button>

                </>

              )}

            </div>

          </div>

        </div>

      </main>

    </div>
  );
}


// =====================================================
// RECEIPT ROW
// =====================================================

function ReceiptRow({
  label,
  value,
}) {
  return (
    <div className="flex items-start justify-between gap-5">

      <span className="text-sm text-slate-500">
        {label}
      </span>


      <strong className="text-right text-sm text-slate-900">
        {value}
      </strong>

    </div>
  );
}