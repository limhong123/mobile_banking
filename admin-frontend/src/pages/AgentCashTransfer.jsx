import {
  useState,
} from "react";

import {
  Banknote,
  CheckCircle2,
  Copy,
  Phone,
  Send,
  UserRound,
} from "lucide-react";

import Sidebar
  from "../components/Sidebar";

import {
  createCashTransfer,
} from "../api/cashTransferApi";


export default function AgentCashTransfer() {
  const [
    senderPhone,
    setSenderPhone,
  ] = useState("");

  const [
    receiverPhone,
    setReceiverPhone,
  ] = useState("");

  const [
    amount,
    setAmount,
  ] = useState("");

  const [
    loading,
    setLoading,
  ] = useState(false);

  const [
    result,
    setResult,
  ] = useState(null);

  const [
    error,
    setError,
  ] = useState("");

  const [
    copied,
    setCopied,
  ] = useState(false);


  // =====================================================
  // PHONE INPUT
  // =====================================================

  function handlePhoneInput(
    value,
    setter
  ) {
    const cleaned =
      value
        .replace(
          /[^\d+]/g,
          ""
        );

    setter(
      cleaned
    );
  }


  // =====================================================
  // CREATE CASH TRANSFER
  // =====================================================

  async function handleCreate(
    event
  ) {
    event.preventDefault();

    setError("");
    setResult(null);
    setCopied(false);


    const cleanSenderPhone =
      senderPhone.trim();

    const cleanReceiverPhone =
      receiverPhone.trim();

    const transferAmount =
      Number(
        amount
      );


    // ===================================================
    // VALIDATION
    // ===================================================

    if (
      !cleanSenderPhone
    ) {
      setError(
        "Please enter sender phone number."
      );

      return;
    }


    if (
      !cleanReceiverPhone
    ) {
      setError(
        "Please enter receiver phone number."
      );

      return;
    }


    if (
      cleanSenderPhone ===
      cleanReceiverPhone
    ) {
      setError(
        "Sender and receiver phone cannot be the same."
      );

      return;
    }


    if (
      !transferAmount ||
      transferAmount <= 0
    ) {
      setError(
        "Please enter a valid amount."
      );

      return;
    }


    try {
      setLoading(
        true
      );


      const response =
        await createCashTransfer({
          sender_phone:
            cleanSenderPhone,

          receiver_phone:
            cleanReceiverPhone,

          amount:
            transferAmount,
        });


      setResult(
        response.data
      );


      // Clear amount after success
      setAmount("");

    } catch (error) {
      console.error(
        "CREATE CASH TRANSFER ERROR:",
        error
      );


      const detail =
        error.response?.data
          ?.detail;


      if (
        typeof detail ===
        "string"
      ) {
        setError(
          detail
        );

      } else {
        setError(
          "Unable to create cash transfer."
        );
      }

    } finally {
      setLoading(
        false
      );
    }
  }


  // =====================================================
  // COPY CODE
  // =====================================================

  async function copyCode() {
    if (
      !result?.code
    ) {
      return;
    }


    try {
      await navigator
        .clipboard
        .writeText(
          result.code
        );


      setCopied(
        true
      );


      setTimeout(
        () => {
          setCopied(
            false
          );
        },
        1500
      );

    } catch (error) {
      console.error(
        "COPY ERROR:",
        error
      );
    }
  }


  // =====================================================
  // NEW TRANSFER
  // =====================================================

  function createAnother() {
    setSenderPhone("");
    setReceiverPhone("");
    setAmount("");
    setResult(null);
    setError("");
    setCopied(false);
  }


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

        <div className="mb-8">

          <h1 className="text-3xl font-bold tracking-tight text-slate-900">
            Cash Transfer
          </h1>


          <p className="mt-1 text-sm text-slate-500">
            Receive physical cash from sender and create a
            12-digit transfer code for the receiver.
          </p>

        </div>


        {/* =================================================
            ERROR
        ================================================= */}

        {error && (

          <div className="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {error}
          </div>

        )}


        <div className="grid gap-6 xl:grid-cols-2">

          {/* =================================================
              LEFT - FORM
          ================================================= */}

          <form
            onSubmit={
              handleCreate
            }
            className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
          >

            <div className="flex items-center gap-3">

              <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-blue-50 text-blue-600">

                <Send
                  size={22}
                />

              </div>


              <div>

                <h2 className="font-bold text-slate-900">
                  Transfer Information
                </h2>


                <p className="text-xs text-slate-500">
                  Enter sender phone, receiver phone and amount
                </p>

              </div>

            </div>


            {/* =============================================
                SENDER PHONE
            ============================================= */}

            <label className="mt-7 block text-sm font-semibold text-slate-700">
              Sender Phone
              <span className="ml-1 text-red-500">
                *
              </span>
            </label>


            <div className="mt-2 flex items-center rounded-xl border border-slate-200 px-4 transition focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">

              <Phone
                size={18}
                className="shrink-0 text-slate-400"
              />


              <input
                type="tel"
                value={
                  senderPhone
                }
                onChange={(e) =>
                  handlePhoneInput(
                    e.target.value,
                    setSenderPhone
                  )
                }
                className="w-full px-3 py-3 outline-none"
                placeholder="012345678"
                autoComplete="off"
              />

            </div>


            <p className="mt-1 text-xs text-slate-400">
              Phone number of the person giving cash to the agent.
            </p>


            {/* =============================================
                RECEIVER PHONE
            ============================================= */}

            <label className="mt-5 block text-sm font-semibold text-slate-700">
              Receiver Phone
              <span className="ml-1 text-red-500">
                *
              </span>
            </label>


            <div className="mt-2 flex items-center rounded-xl border border-slate-200 px-4 transition focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">

              <UserRound
                size={18}
                className="shrink-0 text-slate-400"
              />


              <input
                type="tel"
                value={
                  receiverPhone
                }
                onChange={(e) =>
                  handlePhoneInput(
                    e.target.value,
                    setReceiverPhone
                  )
                }
                className="w-full px-3 py-3 outline-none"
                placeholder="098494201"
                autoComplete="off"
              />

            </div>


            <p className="mt-1 text-xs text-slate-400">
              The receiver can have a KhmerPay account or receive cash from an agent.
            </p>


            {/* =============================================
                AMOUNT
            ============================================= */}

            <label className="mt-5 block text-sm font-semibold text-slate-700">
              Amount
              <span className="ml-1 text-red-500">
                *
              </span>
            </label>


            <div className="mt-2 flex items-center rounded-xl border border-slate-200 px-4 transition focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">

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
                onChange={(e) =>
                  setAmount(
                    e.target.value
                  )
                }
                className="w-full px-3 py-3 text-xl font-bold text-slate-900 outline-none"
                placeholder="0.00"
              />

            </div>


            {/* =============================================
                INFO
            ============================================= */}



            {/* =============================================
                SUBMIT
            ============================================= */}

            <button
              type="submit"
              disabled={
                loading
              }
              className="mt-6 flex w-full items-center justify-center gap-2 rounded-xl bg-blue-600 py-3.5 font-semibold text-white transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
            >

              <Banknote
                size={19}
              />


              {loading
                ? "Generating..."
                : "Generate 12-Digit Code"}

            </button>

          </form>


          {/* =================================================
              RIGHT - RESULT
          ================================================= */}

          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">

            {!result ? (

              <div className="flex min-h-[500px] flex-col items-center justify-center text-center">

                <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-slate-400">

                  <Banknote
                    size={30}
                  />

                </div>


                <h3 className="mt-4 font-bold text-slate-900">
                  No Transfer Yet
                </h3>


                <p className="mt-2 max-w-sm text-sm leading-6 text-slate-500">
                  Enter sender phone, receiver phone and amount,
                  then generate a 12-digit transfer code.
                </p>

              </div>

            ) : (

              <div>

                {/* SUCCESS */}

                <div className="text-center">

                  <CheckCircle2
                    size={58}
                    className="mx-auto text-green-600"
                  />


                  <h2 className="mt-4 text-xl font-bold text-slate-900">
                    Transfer Created
                  </h2>


                  <p className="mt-2 text-sm text-slate-500">
                    Give this code to the receiver.
                  </p>

                </div>


                {/* CODE */}

                <div className="mt-7 rounded-2xl bg-slate-950 p-6 text-center text-white">

                  <p className="text-xs font-semibold uppercase tracking-widest text-slate-400">
                    12-Digit Code
                  </p>


                  <div className="mt-4 flex items-center justify-center gap-3">

                    <span className="break-all text-3xl font-black tracking-[0.12em]">
                      {
                        result.code
                      }
                    </span>


                    <button
                      type="button"
                      onClick={
                        copyCode
                      }
                      className="shrink-0 rounded-lg bg-white/10 p-2 transition hover:bg-white/20"
                      title="Copy Code"
                    >

                      <Copy
                        size={18}
                      />

                    </button>

                  </div>


                  {copied && (

                    <p className="mt-3 text-xs font-medium text-green-400">
                      Code copied
                    </p>

                  )}

                </div>


                {/* DETAILS */}

                <div className="mt-6 rounded-2xl bg-slate-50 p-5">

                  <Info
                    label="Transfer ID"
                    value={
                      result.transfer_id ||
                      "-"
                    }
                  />


                  <Info
                    label="Sender Phone"
                    value={
                      result.sender_phone ||
                      senderPhone
                    }
                  />


                  <Info
                    label="Receiver Phone"
                    value={
                      result.receiver_phone ||
                      receiverPhone
                    }
                  />


                  <Info
                    label="Amount"
                    value={`$${Number(
                      result.amount ||
                      0
                    ).toFixed(
                      2
                    )}`}
                  />


                  <Info
                    label="Receiver Account"
                    value={
                      result.receiver_has_account
                        ? "KhmerPay account found"
                        : "No KhmerPay account"
                    }
                  />


                  {result.receiver_has_account &&
                    result.receiver_name && (

                      <Info
                        label="Receiver Name"
                        value={
                          result.receiver_name
                        }
                      />

                    )}


                  <Info
                    label="Status"
                    value={
                      result.status ||
                      "pending"
                    }
                  />


                  {result.expires_at && (

                    <Info
                      label="Expires"
                      value={
                        new Date(
                          result.expires_at
                        ).toLocaleString()
                      }
                    />

                  )}

                </div>


                {/* RECEIVE OPTIONS */}

                <div className="mt-5 rounded-xl border border-blue-200 bg-blue-50 p-4">

                  <p className="font-semibold text-blue-900">
                    Receiver Options
                  </p>


                  <p className="mt-2 text-sm leading-6 text-blue-800">

                    {result.receiver_has_account
                      ? "The receiver can either receive physical cash from an agent or enter this code in the KhmerPay app to receive money into their account."
                      : "The receiver does not have a KhmerPay account, so they can receive physical cash from an agent using this code and their phone number."}

                  </p>

                </div>


                {/* NEW TRANSFER */}

                <button
                  type="button"
                  onClick={
                    createAnother
                  }
                  className="mt-6 w-full rounded-xl border border-slate-200 bg-white py-3 font-semibold text-slate-700 transition hover:bg-slate-50"
                >
                  Create Another Transfer
                </button>

              </div>

            )}

          </div>

        </div>

      </main>

    </div>
  );
}


// =====================================================
// INFO ROW
// =====================================================

function Info({
  label,
  value,
}) {
  return (
    <div className="flex items-start justify-between gap-5 border-b border-slate-200 py-3 last:border-b-0">

      <span className="text-sm text-slate-500">
        {label}
      </span>


      <strong className="text-right text-sm text-slate-900">
        {value}
      </strong>

    </div>
  );
}