import {
  useEffect,
  useState,
} from "react";

import {
  Banknote,
  History,
  LayoutDashboard,
  LogOut,
  UserCog,
  Users,
  Wallet,
  ArrowRightLeft,
  HandCoins,
  PiggyBank,
  X,
} from "lucide-react";

import {
  NavLink,
  useNavigate,
  useLocation,
} from "react-router-dom";

import { getUsers } from "../api/adminApi";


export default function Sidebar({ isOpen, onClose }) {
  const navigate =
    useNavigate();
  const location =
    useLocation();

  const [userCount, setUserCount] = useState(null);


  // =====================================================
  // CURRENT USER
  // =====================================================

  const user =
    JSON.parse(
      localStorage.getItem(
        "user"
      ) || "{}"
    );


  const role =
    user.role ||
    "admin";


  // =====================================================
  // FETCH USER COUNT FOR SIDEBAR
  // =====================================================

  useEffect(() => {
    if (role === "admin") {
      let isMounted = true;
      getUsers()
        .then((res) => {
          if (!isMounted) return;
          const count =
            typeof res?.count === "number"
              ? res.count
              : Array.isArray(res?.data)
              ? res.data.length
              : 0;
          setUserCount(count);
        })
        .catch((err) => {
          console.error("Failed to load user count for sidebar:", err);
        });

      return () => {
        isMounted = false;
      };
    }
  }, [role, location.pathname]);


  // =====================================================
  // ADMIN MENU
  // =====================================================

  const adminMenus = [
    {
      title: "Dashboard",
      path: "/admin/dashboard",
      icon: LayoutDashboard,
    },

    {
      title: "Users",
      path: "/admin/users",
      icon: Users,
    },

    {
      title: "Agents",
      path: "/admin/agents",
      icon: UserCog,
    },

    {
      title: "System Wallet",
      path: "/admin/wallet",
      icon: Wallet,
    },
    {
      title: "Savings",
      path: "/admin/savings",
      icon: PiggyBank,
    },
  ];


  // =====================================================
  // AGENT MENU
  // =====================================================

  const agentMenus = [
    {
      title:
        "Dashboard",
      path:
        "/agent/dashboard",
      icon:
        LayoutDashboard,
    },

    {
      title:
        "Deposit Money",
      path:
        "/agent/deposit",
      icon:
        Banknote,
    },

    {
      title:
        "Cash Transfer",
      path:
        "/agent/cash-transfer",
      icon:
        ArrowRightLeft,
    },

    {
      title:
        "Cash Payout",
      path:
        "/agent/cash-payout",
      icon:
        HandCoins,
    },

    {
      title:
        "Transactions",
      path:
        "/agent/transactions",
      icon:
        History,
    },
  ];


  // =====================================================
  // MENU BY ROLE
  // =====================================================

  const menus =
    role === "admin"
      ? adminMenus
      : agentMenus;


  // =====================================================
  // LOGOUT
  // =====================================================

  function logout() {
    localStorage.removeItem(
      "access_token"
    );

    localStorage.removeItem(
      "refresh_token"
    );

    localStorage.removeItem(
      "user"
    );

    navigate(
      "/admin/login"
    );
  }


  // =====================================================
  // USER INFO
  // =====================================================

  const fullName =
    `${user.first_name || ""} ${user.last_name || ""}`
      .trim();


  const initial =
    user.first_name
      ?.charAt(0)
      .toUpperCase() ||
    (role === "admin"
      ? "A"
      : "G");


  // =====================================================
  // UI
  // =====================================================

  return (
    <>
      {/* Mobile Backdrop Overlay */}
      {isOpen && (
        <div
          onClick={onClose}
          className="fixed inset-0 z-40 bg-slate-950/60 backdrop-blur-sm lg:hidden"
        />
      )}

      <aside
        className={`fixed left-0 top-0 z-50 flex h-screen w-[255px] flex-col justify-between bg-slate-950 px-4 py-6 text-white transition-transform duration-300 lg:translate-x-0 ${
          isOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"
        }`}
      >

        <div>

          {/* LOGO */}

          <div className="flex items-center justify-between px-1">

            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-blue-600 text-xl font-bold shadow-lg shadow-blue-950/30">
                K
              </div>

              <div>
                <h2 className="text-xl font-bold">
                  KhmerPay
                </h2>

                <p className="text-xs text-slate-400">
                  {role === "admin"
                    ? "Admin Portal"
                    : "Agent Portal"}
                </p>
              </div>
            </div>

            {onClose && (
              <button
                type="button"
                onClick={onClose}
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-800 hover:text-white lg:hidden"
              >
                <X size={18} />
              </button>
            )}

          </div>


          {/* USER CARD */}

          <div className="mt-8 flex items-center gap-3 rounded-2xl border border-white/5 bg-slate-800/80 p-4">

            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-blue-600 font-bold">
              {initial}
            </div>


            <div className="min-w-0">

              <p className="truncate font-semibold">

                {fullName ||
                  (role === "admin"
                    ? "Admin KhmerPay"
                    : "KhmerPay Agent")}

              </p>


              <p className="mt-0.5 text-xs capitalize text-slate-400">
                {role}
              </p>

            </div>

          </div>


          {/* MENU */}

          <nav className="mt-8 space-y-2">

            {menus.map(
              ({
                title,
                path,
                icon: Icon,
              }) => (

                <NavLink
                  key={path}
                  to={path}
                  onClick={() => {
                    if (onClose) onClose();
                  }}
                  className={({
                    isActive,
                  }) =>
                    `flex items-center justify-between gap-3 rounded-xl px-4 py-3 text-sm font-medium transition ${
                      isActive
                        ? "bg-blue-600 text-white shadow-sm shadow-blue-950/20"
                        : "text-slate-300 hover:bg-slate-800 hover:text-white"
                    }`
                  }
                >
                  {({ isActive }) => (
                    <>
                      <div className="flex items-center gap-3 min-w-0">
                        <Icon
                          size={19}
                          className="shrink-0"
                        />

                        <span className="truncate">
                          {title}
                        </span>
                      </div>

                      {title === "Users" && userCount !== null && (
                        <span
                          className={`inline-flex min-w-[22px] items-center justify-center rounded-full px-2 py-0.5 text-xs font-bold transition ${
                            isActive
                              ? "bg-white/20 text-white"
                              : "bg-slate-800 text-slate-300 border border-white/5"
                          }`}
                          title={`Total Users: ${userCount}`}
                        >
                          {userCount}
                        </span>
                      )}
                    </>
                  )}

                </NavLink>

              )
            )}

          </nav>

        </div>


        {/* LOGOUT */}

        <button
          type="button"
          onClick={logout}
          className="flex w-full items-center justify-center gap-2 rounded-xl bg-red-500/10 px-4 py-3 text-sm font-medium text-red-300 transition hover:bg-red-500/20"
        >

          <LogOut
            size={18}
          />

          Logout

        </button>

      </aside>
    </>
  );
}
