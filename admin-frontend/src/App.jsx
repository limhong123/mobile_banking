import {
  BrowserRouter,
  Navigate,
  Route,
  Routes,
} from "react-router-dom";

// Auth
import Login from "./pages/auth/Login";

// Admin Pages
import Dashboard from "./pages/admin/Dashboard";
import Users from "./pages/admin/Users";
import UserKycDetail from "./pages/admin/UserKycDetail";
import Agents from "./pages/admin/Agents";
import SystemWallet from "./pages/admin/SystemWallet";

// Agent Pages
import AgentDashboard from "./pages/agent/Dashboard";
import AgentDeposit from "./pages/agent/Deposit";
import AgentHistory from "./pages/agent/History";
import AgentCashTransfer from "./pages/agent/CashTransfer";
import AgentCashPayout from "./pages/agent/CashPayout";

// Components & Layouts
import ProtectedRoute from "./components/ProtectedRoute";
import MainLayout from "./layouts/MainLayout";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* ROOT */}
        <Route
          path="/"
          element={<Navigate to="/admin/login" replace />}
        />

        {/* LOGIN */}
        <Route
          path="/admin/login"
          element={<Login />}
        />

        {/* =================================================
            ADMIN ROUTES
        ================================================= */}
        <Route
          element={
            <ProtectedRoute roles={["admin"]}>
              <MainLayout />
            </ProtectedRoute>
          }
        >
          <Route path="/admin/dashboard" element={<Dashboard />} />
          <Route path="/admin/users" element={<Users />} />
          <Route path="/admin/users/:id" element={<UserKycDetail />} />
          <Route path="/admin/agents" element={<Agents />} />
          <Route path="/admin/wallet" element={<SystemWallet />} />
        </Route>

        {/* =================================================
            AGENT ROUTES
        ================================================= */}
        <Route
          element={
            <ProtectedRoute roles={["agent"]}>
              <MainLayout />
            </ProtectedRoute>
          }
        >
          <Route path="/agent/dashboard" element={<AgentDashboard />} />
          <Route path="/agent/cash-transfer" element={<AgentCashTransfer />} />
          <Route path="/agent/cash-payout" element={<AgentCashPayout />} />
          <Route path="/agent/deposit" element={<AgentDeposit />} />
          <Route path="/agent/transactions" element={<AgentHistory />} />
        </Route>

        {/* FALLBACK */}
        <Route path="*" element={<FallbackRoute />} />
      </Routes>
    </BrowserRouter>
  );
}

/* =========================================================
   FALLBACK ROUTE
========================================================= */

function FallbackRoute() {
  const token = localStorage.getItem("access_token");
  const rawUser = localStorage.getItem("user");

  if (!token || !rawUser) {
    return <Navigate to="/admin/login" replace />;
  }

  let user;
  try {
    user = JSON.parse(rawUser);
  } catch {
    localStorage.clear();
    return <Navigate to="/admin/login" replace />;
  }

  if (user.role === "admin") {
    return <Navigate to="/admin/dashboard" replace />;
  }

  if (user.role === "agent") {
    return <Navigate to="/agent/dashboard" replace />;
  }

  return <Navigate to="/admin/login" replace />;
}