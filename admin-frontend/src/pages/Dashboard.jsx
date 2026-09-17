import {
  useEffect,
  useState,
} from "react";

import {
  ShieldCheck,
  UserCog,
  Users,
  Wallet,
} from "lucide-react";

import Sidebar
  from "../components/Sidebar";

import {
  getAgents,
  getUsers,
} from "../api/adminApi";


export default function Dashboard() {
  const [
    users,
    setUsers,
  ] = useState([]);

  const [
    agents,
    setAgents,
  ] = useState([]);

  const [
    loading,
    setLoading,
  ] = useState(true);


  useEffect(() => {
    loadDashboard();
  }, []);


  async function loadDashboard() {
    try {
      setLoading(true);

      const [
        usersResponse,
        agentsResponse,
      ] = await Promise.all([
        getUsers(),
        getAgents(),
      ]);

      setUsers(
        usersResponse?.data ||
        []
      );

      setAgents(
        agentsResponse?.data ||
        []
      );

    } catch (error) {
      console.error(
        "DASHBOARD ERROR:",
        error
      );

    } finally {
      setLoading(false);
    }
  }


  const verifiedUsers =
    users.filter(
      (user) =>
        user.kyc_status ===
        "approved"
    ).length;


  const totalBalance =
    users.reduce(
      (
        total,
        user
      ) =>
        total +
        Number(
          user.balance || 0
        ),
      0
    );


  function getKycLabel(
    status
  ) {
    switch (status) {
      case "approved":
        return "Approved";

      case "rejected":
        return "Rejected";

      case "pending_review":
        return "Pending Review";

      case "nid_front_uploaded":
      case "nid_uploaded":
      case "nid_confirmed":
        return "In Progress";

      case "not_submitted":
        return "Not Submitted";

      default:
        return status || "-";
    }
  }


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
      status ===
      "pending_review"
    ) {
      return (
        "bg-amber-50 text-amber-700"
      );
    }

    return (
      "bg-slate-100 text-slate-600"
    );
  }


  return (
    <div className="min-h-screen bg-slate-50">

      <Sidebar />


      <main className="ml-[255px] min-h-screen p-8">

        {/* HEADER */}

        <div className="mb-8">

          <h1 className="text-3xl font-bold tracking-tight text-slate-900">
            Admin Dashboard
          </h1>

          <p className="mt-1 text-sm text-slate-500">
            KhmerPay system overview
          </p>

        </div>


        {loading ? (

          <div className="flex min-h-[320px] items-center justify-center rounded-2xl border border-slate-200 bg-white shadow-sm">

            <div className="text-center">

              <div className="mx-auto h-8 w-8 animate-spin rounded-full border-4 border-slate-200 border-t-blue-600" />

              <p className="mt-4 text-sm text-slate-500">
                Loading dashboard...
              </p>

            </div>

          </div>

        ) : (

          <>

            {/* STATS */}

            <div className="mb-7 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">

              <StatCard
                title="Total Users"
                value={
                  users.length
                }
                icon={Users}
              />

              <StatCard
                title="Agents"
                value={
                  agents.length
                }
                icon={UserCog}
              />

              <StatCard
                title="Verified Users"
                value={
                  verifiedUsers
                }
                icon={
                  ShieldCheck
                }
              />

              <StatCard
                title="Customer Balance"
                value={
                  `$${totalBalance.toLocaleString(
                    undefined,
                    {
                      minimumFractionDigits:
                        2,

                      maximumFractionDigits:
                        2,
                    }
                  )}`
                }
                icon={Wallet}
              />

            </div>


            {/* RECENT CUSTOMERS */}

            <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">

              <div className="border-b border-slate-100 px-6 py-5">

                <h2 className="text-xl font-bold text-slate-900">
                  Recent Customers
                </h2>

                <p className="mt-1 text-sm text-slate-500">
                  Latest KhmerPay customers
                </p>

              </div>


              {users.length === 0 ? (

                <div className="flex min-h-[220px] items-center justify-center text-sm text-slate-500">
                  No customers found
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
                          KYC
                        </th>

                        <th className="whitespace-nowrap px-6 py-4">
                          Account Status
                        </th>

                      </tr>

                    </thead>


                    <tbody className="divide-y divide-slate-100">

                      {users
                        .slice(
                          0,
                          5
                        )
                        .map(
                          (user) => (

                            <tr
                              key={
                                user.id
                              }
                              className="transition hover:bg-slate-50"
                            >

                              <td className="whitespace-nowrap px-6 py-5">

                                <div className="flex items-center gap-3">

                                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-50 font-bold text-blue-600">
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


                              <td className="whitespace-nowrap px-6 py-5 text-sm text-slate-600">
                                {
                                  user.phone_number
                                }
                              </td>


                              <td className="whitespace-nowrap px-6 py-5 font-semibold text-slate-900">
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
                              </td>


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


function StatCard({
  title,
  value,
  icon: Icon,
}) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">

      <div className="flex items-center gap-4">

        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-blue-50 text-blue-600">
          <Icon size={23} />
        </div>


        <div>

          <p className="text-sm font-medium text-slate-500">
            {title}
          </p>

          <h2 className="mt-1 text-2xl font-bold text-slate-900">
            {value}
          </h2>

        </div>

      </div>

    </div>
  );
}