import {
  useState,
} from "react";

import {
  Eye,
  EyeOff,
  LockKeyhole,
  Phone,
} from "lucide-react";

import {
  useNavigate,
} from "react-router-dom";

import api from "../../api/api";


export default function AdminLogin() {
  const navigate =
    useNavigate();


  const [
    phoneNumber,
    setPhoneNumber,
  ] = useState("");


  const [
    pin,
    setPin,
  ] = useState("");


  const [
    showPin,
    setShowPin,
  ] = useState(false);


  const [
    loading,
    setLoading,
  ] = useState(false);


  const [
    error,
    setError,
  ] = useState("");


  // =====================================================
  // LOGIN
  // =====================================================

  async function handleLogin(
    event
  ) {
    event.preventDefault();


    if (loading) {
      return;
    }


    setError("");


    const phone =
      phoneNumber.trim();


    const cleanPin =
      pin.trim();


    // ===================================================
    // VALIDATION
    // ===================================================

    if (!phone) {
      setError(
        "Please enter phone number."
      );

      return;
    }


    if (
      !/^\d{6}$/.test(
        cleanPin
      )
    ) {
      setError(
        "PIN must be exactly 6 digits."
      );

      return;
    }


    try {
      setLoading(true);


      // =================================================
      // REMOVE OLD LOGIN SESSION
      // =================================================

      localStorage.removeItem(
        "access_token"
      );

      localStorage.removeItem(
        "refresh_token"
      );

      localStorage.removeItem(
        "user"
      );


      // =================================================
      // LOGIN REQUEST
      // =================================================

      const response =
        await api.post(
          "/auth/login",
          {
            phone_number:
              phone,

            pin:
              cleanPin,
          }
        );


      const data =
        response?.data;


      if (!data) {
        throw new Error(
          "Invalid server response."
        );
      }


      const accessToken =
        data.access_token;


      const refreshToken =
        data.refresh_token;


      const user =
        data.user;


      // =================================================
      // CHECK RESPONSE
      // =================================================

      if (!accessToken) {
        throw new Error(
          "Access token not found."
        );
      }


      if (!user) {
        throw new Error(
          "User information not found."
        );
      }


      const role =
        user.role
          ?.toString()
          .trim()
          .toLowerCase();


      // =================================================
      // BLOCK CUSTOMER
      // =================================================

      if (
        role !== "admin" &&
        role !== "agent"
      ) {
        setError(
          "Customer account cannot access this portal."
        );

        return;
      }


      // =================================================
      // ACTIVE CHECK
      // =================================================

      if (
        user.is_active ===
        false
      ) {
        setError(
          "Your account has been disabled."
        );

        return;
      }


      // =================================================
      // SAVE LOGIN SESSION
      // =================================================

      localStorage.setItem(
        "access_token",
        accessToken
      );


      if (refreshToken) {
        localStorage.setItem(
          "refresh_token",
          refreshToken
        );
      }


      localStorage.setItem(
        "user",
        JSON.stringify(
          user
        )
      );


      // =================================================
      // ADMIN
      // =================================================

      if (
        role === "admin"
      ) {
        navigate(
          "/admin/dashboard",
          {
            replace: true,
          }
        );

        return;
      }


      // =================================================
      // AGENT
      // =================================================

      if (
        role === "agent"
      ) {
        navigate(
          "/agent/dashboard",
          {
            replace: true,
          }
        );

        return;
      }

    } catch (error) {
      console.error(
        "LOGIN ERROR:",
        error
      );


      const detail =
        error.response?.data
          ?.detail;


      // =================================================
      // BACKEND STRING ERROR
      // =================================================

      if (
        typeof detail ===
        "string"
      ) {
        setError(
          detail
        );

        return;
      }


      // =================================================
      // BACKEND OBJECT ERROR
      // =================================================

      if (
        detail &&
        typeof detail ===
          "object"
      ) {
        setError(
          detail.message ||
          "Login failed."
        );

        return;
      }


      // =================================================
      // JAVASCRIPT ERROR
      // =================================================

      if (
        error.message
      ) {
        setError(
          error.message
        );

        return;
      }


      setError(
        "Login failed. Please try again."
      );

    } finally {
      setLoading(false);
    }
  }


  // =====================================================
  // UI
  // =====================================================

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 px-5">

      <div className="w-full max-w-[430px] rounded-3xl border border-slate-200 bg-white p-8 shadow-xl shadow-slate-200/60">


        {/* LOGO */}

        <div className="mb-8">

          <div className="mb-5 flex h-16 w-16 items-center justify-center rounded-2xl bg-blue-600 text-2xl font-bold text-white shadow-lg shadow-blue-200">
            K
          </div>


          <h1 className="text-3xl font-bold tracking-tight text-slate-900">
            KhmerPay
          </h1>


          <p className="mt-1 text-base text-slate-500">
            Admin & Agent Portal
          </p>

        </div>


        {/* ERROR */}

        {error && (

          <div className="mb-5 rounded-xl border border-red-100 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {error}
          </div>

        )}


        {/* FORM */}

        <form
          onSubmit={
            handleLogin
          }
          className="space-y-5"
        >


          {/* PHONE */}

          <div>

            <label className="mb-2 block text-sm font-semibold text-slate-800">
              Phone Number
            </label>


            <div className="flex items-center rounded-xl border border-slate-200 bg-white px-4 transition focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">

              <Phone
                size={19}
                className="shrink-0 text-slate-400"
              />


              <input
                type="text"
                inputMode="tel"
                autoComplete="username"
                placeholder="012345678"
                value={
                  phoneNumber
                }
                disabled={
                  loading
                }
                onChange={(
                  event
                ) =>
                  setPhoneNumber(
                    event.target.value
                  )
                }
                className="w-full bg-transparent px-3 py-3.5 text-sm text-slate-900 outline-none placeholder:text-slate-400 disabled:cursor-not-allowed"
              />

            </div>

          </div>


          {/* PIN */}

          <div>

            <label className="mb-2 block text-sm font-semibold text-slate-800">
              6-Digit PIN
            </label>


            <div className="flex items-center rounded-xl border border-slate-200 bg-white px-4 transition focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">

              <LockKeyhole
                size={19}
                className="shrink-0 text-slate-400"
              />


              <input
                type={
                  showPin
                    ? "text"
                    : "password"
                }
                inputMode="numeric"
                autoComplete="current-password"
                placeholder="••••••"
                maxLength={6}
                value={pin}
                disabled={
                  loading
                }
                onChange={(
                  event
                ) => {
                  const value =
                    event.target.value
                      .replace(
                        /\D/g,
                        ""
                      )
                      .slice(
                        0,
                        6
                      );


                  setPin(
                    value
                  );
                }}
                className="w-full bg-transparent px-3 py-3.5 text-sm text-slate-900 outline-none placeholder:text-slate-400 disabled:cursor-not-allowed"
              />


              <button
                type="button"
                disabled={
                  loading
                }
                onClick={() =>
                  setShowPin(
                    (
                      current
                    ) =>
                      !current
                  )
                }
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-slate-400 transition hover:bg-slate-100 hover:text-slate-700"
              >

                {showPin ? (

                  <EyeOff
                    size={18}
                  />

                ) : (

                  <Eye
                    size={18}
                  />

                )}

              </button>

            </div>

          </div>


          {/* LOGIN BUTTON */}

          <button
            type="submit"
            disabled={
              loading
            }
            className="flex min-h-[52px] w-full items-center justify-center rounded-xl bg-blue-600 px-4 font-semibold text-white shadow-lg shadow-blue-200 transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:bg-blue-400"
          >

            {loading ? (

              <div className="flex items-center gap-3">

                <div className="h-5 w-5 animate-spin rounded-full border-2 border-white/40 border-t-white" />

                <span>
                  Signing in...
                </span>

              </div>

            ) : (

              "Sign In"

            )}

          </button>

        </form>


        {/* FOOTER */}

        <div className="mt-7 border-t border-slate-100 pt-5 text-center">

          <p className="text-xs leading-5 text-slate-400">
            This portal is available only
            for authorized KhmerPay
            administrators and agents.
          </p>

        </div>

      </div>

    </div>
  );
}
