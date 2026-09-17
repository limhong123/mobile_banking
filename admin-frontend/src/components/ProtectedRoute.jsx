import {
  Navigate,
} from "react-router-dom";


export default function ProtectedRoute({
  children,
  roles = [],
}) {
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
    roles.length > 0 &&
    !roles.includes(
      user.role
    )
  ) {
    if (
      user.role === "admin"
    ) {
      return (
        <Navigate
          to="/admin/dashboard"
          replace
        />
      );
    }

    if (
      user.role === "agent"
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

  return children;
}