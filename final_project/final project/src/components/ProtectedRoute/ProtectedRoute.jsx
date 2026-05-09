// src/components/ProtectedRoute/ProtectedRoute.jsx
// ─── Route Guard — redirects based on login + role ────────────────────────────
import { Navigate, useLocation } from "react-router-dom";
import { isLoggedIn, canAccess, getUserRole, ROLE_PERMISSIONS } from "../../utils/auth";

export default function ProtectedRoute({ children }) {
  const location = useLocation();

  // Not logged in → go to login
  if (!isLoggedIn()) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // Logged in but no access to this route → redirect to allowed page
  if (!canAccess(location.pathname)) {
    const role = getUserRole();
    const firstAllowed = ROLE_PERMISSIONS[role]?.routes?.[0] || "/login";
    return (
      <div className="flex items-center justify-center h-screen bg-gray-50">
        <div className="text-center max-w-sm px-6">
          <div className="text-5xl mb-4">🚫</div>
          <h2 className="text-xl font-bold text-gray-900 mb-2">Access Denied</h2>
          <p className="text-sm text-gray-500 mb-6">
            Your <strong>{role}</strong> account does not have permission to view this page.
          </p>
          <a href={firstAllowed}
            className="inline-block bg-gray-900 text-white text-sm font-medium px-6 py-2.5 rounded-lg hover:bg-gray-700 transition-colors">
            Go to Dashboard
          </a>
        </div>
      </div>
    );
  }

  return children;
}
