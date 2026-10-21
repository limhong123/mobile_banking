import {
  useState,
} from "react";

import {
  Banknote,
  CheckCircle2,
  Search,
} from "lucide-react";

import {
  checkCashPickup,
  claimCashPickup,
} from "../../api/cashTransferApi";


export default function AgentCashPayout() {
  const [
    code,
    setCode,
  ] = useState("");

  const [
    receiverPhone,
    setReceiverPhone,
  ] = useState("");

  const [
    transfer,
    setTransfer,
  ] = useState(null);

  const [
    loading,
    setLoading,
  ] = useState(false);

  const [
    success,
    setSuccess,
  ] = useState(null);

  const [
    error,
    setError,
  ] = useState("");


  function handleCode(
    value
  ) {
    setCode(
      value
        .replace(
          /\D/g,
          ""
        )
        .slice(
          0,
          12
        )
    );
  }


  async function handleCheck() {
    if (
      code.length !== 12 ||
      !receiverPhone.trim()
    ) {
      setError(
        "Enter the 12-digit code and receiver phone."
      );

      return;
    }

    try {
      setLoading(true);
      setError("");

      const response =
        await checkCashPickup({
          code,
          receiverPhone,
        });

      setTransfer(
        response.data
      );

    } catch (error) {
      setTransfer(null);

      setError(
        error.response?.data
          ?.detail ||
        "Transfer not found"
      );

    } finally {
      setLoading(false);
    }
  }


  async function handlePayout() {
    if (!transfer) {
      return;
    }

    const confirmed =
      window.confirm(
        `Give $${Number(
          transfer.amount
        ).toFixed(2)} cash to receiver?`
      );

    if (!confirmed) {
      return;
    }

    try {
      setLoading(true);

      const response =
        await claimCashPickup({
          code,
          receiverPhone,
        });

      setSuccess(
        response.data
      );

      setTransfer(null);

    } catch (error) {
      setError(
        error.response?.data
          ?.detail ||
        "Cash payout failed"
      );

    } finally {
      setLoading(false);
    }
  }


  return (
    <>

        <h1 className="text-3xl font-bold text-slate-900">
          Cash Payout
        </h1>

        <p className="mt-1 text-sm text-slate-500">
          Verify a receiver using transfer code and phone number.
        </p>


        {error && (
          <div className="mt-6 rounded-xl border border-red-200 bg-red-50 p-4 text-red-700">
            {error}
          </div>
        )}


        <div className="mt-8 max-w-2xl rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">

          <label className="text-sm font-semibold text-slate-700">
            12-Digit Code
          </label>

          <input
            value={code}
            onChange={(e) =>
              handleCode(
                e.target.value
              )
            }
            inputMode="numeric"
            className="mt-2 w-full rounded-xl border border-slate-200 px-4 py-3 text-xl font-bold tracking-widest outline-none focus:border-blue-500"
            placeholder="583104927611"
          />


          <label className="mt-5 block text-sm font-semibold text-slate-700">
            Receiver Phone
          </label>

          <input
            value={receiverPhone}
            onChange={(e) =>
              setReceiverPhone(
                e.target.value
              )
            }
            className="mt-2 w-full rounded-xl border border-slate-200 px-4 py-3 outline-none focus:border-blue-500"
            placeholder="098494201"
          />


          <button
            onClick={
              handleCheck
            }
            disabled={
              loading
            }
            className="mt-6 flex w-full items-center justify-center gap-2 rounded-xl bg-blue-600 py-3.5 font-semibold text-white"
          >
            <Search size={18} />

            Check Transfer
          </button>


          {transfer && (

            <div className="mt-7 rounded-2xl border border-green-200 bg-green-50 p-5">

              <Info
                label="Sender"
                value={
                  transfer.sender_name
                }
              />

              <Info
                label="Receiver"
                value={
                  transfer.receiver_name ||
                  transfer.receiver_phone
                }
              />

              <Info
                label="Amount"
                value={`$${Number(
                  transfer.amount
                ).toFixed(2)}`}
              />


              <button
                onClick={
                  handlePayout
                }
                disabled={
                  loading
                }
                className="mt-6 flex w-full items-center justify-center gap-2 rounded-xl bg-green-600 py-3.5 font-semibold text-white"
              >
                <Banknote size={18} />

                Confirm Cash Payout
              </button>

            </div>

          )}


          {success && (

            <div className="mt-7 text-center">

              <CheckCircle2
                size={56}
                className="mx-auto text-green-600"
              />

              <h2 className="mt-3 text-xl font-bold">
                Cash Payout Successful
              </h2>

              <p className="mt-2 text-3xl font-black">
                ${Number(
                  success.amount
                ).toFixed(2)}
              </p>

            </div>

          )}

        </div>

      </>
  );
}


function Info({
  label,
  value,
}) {
  return (
    <div className="mb-3 flex justify-between gap-5">
      <span className="text-slate-500">
        {label}
      </span>

      <strong>
        {value}
      </strong>
    </div>
  );
}
