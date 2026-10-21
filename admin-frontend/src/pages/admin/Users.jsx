import {
  useEffect,
  useState,
} from "react";

import {
  Eye,
  Power,
  Search,
  UsersRound,
  SlidersHorizontal,
} from "lucide-react";

import BalanceAdjustmentModal from "../../components/BalanceAdjustmentModal";

import {
  useNavigate,
} from "react-router-dom";

import {
  getUsers,
  toggleUserStatus,
} from "../../api/adminApi";


export default function Users() {
  const navigate =
    useNavigate();

  const [
    users,
    setUsers,
  ] = useState([]);

  const [
    search,
    setSearch,
  ] = useState("");

  const [
    loading,
    setLoading,
  ] = useState(true);

  const [
    adjustTarget,
    setAdjustTarget,
  ] = useState(null);


  useEffect(() => {
    loadUsers();
  }, []);


  async function loadUsers() {
    try {
      setLoading(true);

      const response =
        await getUsers();

      setUsers(
        response?.data ||
        []
      );

    } catch (error) {
      console.error(
        "LOAD USERS ERROR:",
        error
      );

    } finally {
      setLoading(false);
    }
  }


  // =====================================================
  // VIEW USER
  // =====================================================

  function handleView(
    user
  ) {
    navigate(
      `/admin/users/${user.id}`
    );
  }


  // =====================================================
  // ENABLE / DISABLE
  // =====================================================

  async function handleStatus(
    user
  ) {
    const confirmed =
      window.confirm(
        user.is_active
          ? `Disable ${user.first_name} ${user.last_name}?`
          : `Enable ${user.first_name} ${user.last_name}?`
      );

    if (!confirmed) {
      return;
    }

    try {
      await toggleUserStatus(
        user.id
      );

      await loadUsers();

    } catch (error) {
      console.error(
        "USER STATUS ERROR:",
        error
      );

      const detail =
        error.response?.data
          ?.detail;

      alert(
        typeof detail ===
        "string"
          ? detail
          : "Unable to update user"
      );
    }
  }


  // =====================================================
  // KYC LABEL
  // =====================================================

  function getKycLabel(
    status
  ) {
    switch (status) {
      case "approved":
        return "Approved";

      case "rejected":
        return "Rejected";

      case "nid_uploaded":
        return "Face Verification";

      case "not_submitted":
        return "Not Submitted";

      default:
        return status || "-";
    }
  }


  // =====================================================
  // KYC COLOR
  // =====================================================

  function getKycClass(
    status
  ) {
    if (
      status === "approved"
    ) {
      return (
        "bg-green-50 text-green-700"
      );
    }

    if (
      status === "rejected"
    ) {
      return (
        "bg-red-50 text-red-700"
      );
    }

    if (
      status === "nid_uploaded"
    ) {
      return (
        "bg-blue-50 text-blue-700"
      );
    }

    return (
      "bg-slate-100 text-slate-600"
    );
  }


  // =====================================================
  // FILTER
  // =====================================================

  const filteredUsers =
    users.filter(
      (user) => {
        const text =
          `${
            user.first_name || ""
          } ${
            user.last_name || ""
          } ${
            user.phone_number || ""
          }`
            .toLowerCase();

        return text.includes(
          search
            .trim()
            .toLowerCase()
        );
      }
    );


  return (
    <>

        {/* HEADER */}

        <div className="mb-8">

          <h1 className="text-3xl font-bold tracking-tight text-slate-900">
            Users
          </h1>

          <p className="mt-1 text-sm text-slate-500">
            Manage KhmerPay customers
            and view KYC results
          </p>

        </div>


        {/* SEARCH */}

        <div className="mb-6 flex max-w-md items-center gap-3 rounded-xl border border-slate-200 bg-white px-4 shadow-sm transition focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">

          <Search
            size={19}
            className="shrink-0 text-slate-400"
          />

          <input
            type="text"
            placeholder="Search name or phone..."
            value={search}
            onChange={(event) =>
              setSearch(
                event.target.value
              )
            }
            className="w-full bg-transparent py-3 text-sm text-slate-900 outline-none placeholder:text-slate-400"
          />

        </div>


        {/* TABLE */}

        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">

          {loading ? (

            <div className="flex min-h-[280px] items-center justify-center">

              <div className="text-center">

                <div className="mx-auto h-8 w-8 animate-spin rounded-full border-4 border-slate-200 border-t-blue-600" />

                <p className="mt-4 text-sm text-slate-500">
                  Loading customers...
                </p>

              </div>

            </div>

          ) : filteredUsers.length ===
            0 ? (

            <div className="flex min-h-[280px] flex-col items-center justify-center p-8 text-center">

              <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-slate-100 text-slate-400">

                <UsersRound
                  size={27}
                />

              </div>

              <h3 className="font-semibold text-slate-800">
                No users found
              </h3>

              <p className="mt-1 text-sm text-slate-500">
                No customer matches
                your search.
              </p>

            </div>

          ) : (

            <div className="overflow-x-auto">

              <table className="w-full border-collapse">

                <thead className="bg-slate-50">

                  <tr className="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">

                    <th className="whitespace-nowrap px-6 py-4">
                      Customer
                    </th>

                    <th className="whitespace-nowrap px-6 py-4">
                      Phone
                    </th>

                    <th className="whitespace-nowrap px-6 py-4">
                      Balance
                    </th>

                    <th className="whitespace-nowrap px-6 py-4">
                      KYC Status
                    </th>

                    <th className="whitespace-nowrap px-6 py-4">
                      Account Status
                    </th>

                    <th className="whitespace-nowrap px-6 py-4">
                      Actions
                    </th>

                  </tr>

                </thead>


                <tbody className="divide-y divide-slate-100">

                  {filteredUsers.map(
                    (user) => (

                      <tr
                        key={
                          user.id
                        }
                        className="transition hover:bg-slate-50"
                      >

                        {/* CUSTOMER */}

                        <td className="whitespace-nowrap px-6 py-5">

                          <div className="flex items-center gap-3">

                            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-blue-50 font-bold text-blue-600">

                              {user.first_name
                                ?.charAt(0)
                                .toUpperCase() ||
                                "U"}

                            </div>


                            <div>

                              <p className="font-semibold text-slate-900">

                                {
                                  user.first_name
                                }{" "}

                                {
                                  user.last_name
                                }

                              </p>

                              <p className="mt-0.5 text-xs text-slate-400">
                                Customer
                              </p>

                            </div>

                          </div>

                        </td>


                        {/* PHONE */}

                        <td className="whitespace-nowrap px-6 py-5 text-sm text-slate-600">
                          {
                            user.phone_number
                          }
                        </td>


                        {/* BALANCE */}

                        <td className="whitespace-nowrap px-6 py-5">

                          <p className="font-bold text-slate-900">

                            $

                            {Number(
                              user.balance ||
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

                          <p className="mt-0.5 text-xs text-slate-400">

                            {user.currency ||
                              "USD"}

                          </p>

                        </td>


                        {/* KYC */}

                        <td className="whitespace-nowrap px-6 py-5">

                          <span
                            className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${getKycClass(
                              user.kyc_status
                            )}`}
                          >
                            {getKycLabel(
                              user.kyc_status
                            )}
                          </span>

                        </td>


                        {/* ACCOUNT STATUS */}

                        <td className="whitespace-nowrap px-6 py-5">

                          <span
                            className={
                              user.is_active
                                ? "inline-flex rounded-full bg-green-50 px-3 py-1 text-xs font-semibold text-green-700"
                                : "inline-flex rounded-full bg-red-50 px-3 py-1 text-xs font-semibold text-red-700"
                            }
                          >
                            {user.is_active
                              ? "Active"
                              : "Disabled"}
                          </span>

                        </td>


                        {/* ACTIONS */}

                        <td className="whitespace-nowrap px-6 py-5">

                          <div className="flex flex-wrap items-center gap-2">

                            <button
                              type="button"
                              onClick={() =>
                                setAdjustTarget({
                                  id: user.id,
                                  name: `${user.first_name || ""} ${user.last_name || ""}`.trim() || "Customer",
                                  phone: user.phone_number,
                                  balance: user.balance,
                                  currency: user.currency || "USD",
                                  type: "user",
                                })
                              }
                              className="inline-flex items-center gap-1.5 rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs font-semibold text-emerald-700 transition hover:bg-emerald-100"
                            >
                              <SlidersHorizontal size={14} />
                              Debit / Credit
                            </button>

                            <button
                              type="button"
                              onClick={() =>
                                handleView(
                                  user
                                )
                              }
                              className="inline-flex items-center gap-1.5 rounded-lg border border-blue-200 bg-blue-50 px-3 py-2 text-xs font-semibold text-blue-700 transition hover:bg-blue-100"
                            >

                              <Eye
                                size={15}
                              />

                              View

                            </button>


                            <button
                              type="button"
                              onClick={() =>
                                handleStatus(
                                  user
                                )
                              }
                              className={
                                user.is_active
                                  ? "inline-flex items-center gap-1.5 rounded-lg border border-red-200 bg-white px-3 py-2 text-xs font-semibold text-red-700 transition hover:bg-red-50"
                                  : "inline-flex items-center gap-1.5 rounded-lg border border-green-200 bg-green-50 px-3 py-2 text-xs font-semibold text-green-700 transition hover:bg-green-100"
                              }
                            >

                              <Power
                                size={15}
                              />

                              {user.is_active
                                ? "Disable"
                                : "Enable"}

                            </button>

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

        <BalanceAdjustmentModal
          isOpen={Boolean(adjustTarget)}
          onClose={() => setAdjustTarget(null)}
          target={adjustTarget}
          onSuccess={loadUsers}
        />

      </>
  );
}
