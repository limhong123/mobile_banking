import {
  BrowserRouter,
  Navigate,
  Route,
  Routes,
} from "react-router-dom";

import AdminLogin
  from "./pages/AdminLogin";

import Dashboard
  from "./pages/Dashboard";

import Users
  from "./pages/Users";

import UserKycDetail
  from "./pages/UserKycDetail";

import Agents
  from "./pages/Agents";

import SystemWallet
  from "./pages/SystemWallet";

import AgentDashboard
  from "./pages/AgentDashboard";

import AgentDeposit
  from "./pages/AgentDeposit";

import AgentHistory
  from "./pages/AgentHistory";

import ProtectedRoute
  from "./components/ProtectedRoute";

import AgentCashTransfer
  from "./pages/AgentCashTransfer";

import AgentCashPayout
  from "./pages/AgentCashPayout";
export default function App() {
  return (
    <BrowserRouter>

      <Routes>

        {/* ROOT */}

        <Route
          path="/"
          element={
            <Navigate
              to="/admin/login"
              replace
            />
          }
        />


        {/* LOGIN */}

        <Route
          path="/admin/login"
          element={
            <AdminLogin />
          }
        />


        {/* =================================================
            ADMIN ROUTES
        ================================================= */}

        <Route
          path="/admin/dashboard"
          element={
            <ProtectedRoute
              roles={["admin"]}
            >
              <Dashboard />
            </ProtectedRoute>
          }
        />


        <Route
          path="/admin/users"
          element={
            <ProtectedRoute
              roles={["admin"]}
            >
              <Users />
            </ProtectedRoute>
          }
        />


        <Route
          path="/admin/users/:id"
          element={
            <ProtectedRoute
              roles={["admin"]}
            >
              <UserKycDetail />
            </ProtectedRoute>
          }
        />


        <Route
          path="/admin/agents"
          element={
            <ProtectedRoute
              roles={["admin"]}
            >
              <Agents />
            </ProtectedRoute>
          }
        />


        <Route
          path="/admin/wallet"
          element={
            <ProtectedRoute
              roles={["admin"]}
            >
              <SystemWallet />
            </ProtectedRoute>
          }
        />


        {/* =================================================
            AGENT ROUTES
        ================================================= */}

        <Route
          path="/agent/dashboard"
          element={
            <ProtectedRoute
              roles={["agent"]}
            >
              <AgentDashboard />
            </ProtectedRoute>
          }
        />

<Route
  path="/agent/cash-transfer"
  element={
    <ProtectedRoute
      roles={["agent"]}
    >
      <AgentCashTransfer />
    </ProtectedRoute>
  }
/>

<Route
  path="/agent/cash-payout"
  element={
    <ProtectedRoute
      roles={["agent"]}
    >
      <AgentCashPayout />
    </ProtectedRoute>
  }
/>
        <Route
          path="/agent/deposit"
          element={
            <ProtectedRoute
              roles={["agent"]}
            >
              <AgentDeposit />
            </ProtectedRoute>
          }
        />


        <Route
          path="/agent/transactions"
          element={
            <ProtectedRoute
              roles={["agent"]}
            >
              <AgentHistory />
            </ProtectedRoute>
          }
        />


        {/* FALLBACK */}

        <Route
          path="*"
          element={
            <FallbackRoute />
          }
        />

      </Routes>

    </BrowserRouter>
  );
}


/* =========================================================
   FALLBACK ROUTE
========================================================= */

function FallbackRoute() {
  const token =
    localStorage.getItem(
      "access_token"
    );

  const rawUser =
    localStorage.getItem(
      "user"
    );


  if (
    !token ||
    !rawUser
  ) {
    return (
      <Navigate
        to="/admin/login"
        replace
      />
    );
  }


  let user;

  try {
    user =
      JSON.parse(
        rawUser
      );
  } catch {
    localStorage.clear();

    return (
      <Navigate
        to="/admin/login"
        replace
      />
    );
  }


  if (
    user.role ===
    "admin"
  ) {
    return (
      <Navigate
        to="/admin/dashboard"
        replace
      />
    );
  }


  if (
    user.role ===
    "agent"
  ) {
    return (
      <Navigate
        to="/agent/dashboard"
        replace
      />
    );
  }


  return (
    <Navigate
      to="/admin/login"
      replace
    />
  );
}