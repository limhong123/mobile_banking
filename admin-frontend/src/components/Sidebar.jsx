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
} from "lucide-react";

import {
  NavLink,
  useNavigate,
} from "react-router-dom";


export default function Sidebar() {
  const navigate =
    useNavigate();


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
    <aside className="fixed left-0 top-0 z-50 flex h-screen w-[255px] flex-col justify-between bg-slate-950 px-4 py-6 text-white">

      <div>

        {/* LOGO */}

        <div className="flex items-center gap-3 px-1">

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
                className={({
                  isActive,
                }) =>
                  `flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-medium transition ${
                    isActive
                      ? "bg-blue-600 text-white shadow-sm shadow-blue-950/20"
                      : "text-slate-300 hover:bg-slate-800 hover:text-white"
                  }`
                }
              >

                <Icon
                  size={19}
                />

                <span>
                  {title}
                </span>

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
  );
}