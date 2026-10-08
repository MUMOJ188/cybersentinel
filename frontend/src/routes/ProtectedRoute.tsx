import { Navigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import type { Role } from "../types";

/**
 * This only controls what React renders — it is NOT the security
 * boundary. Every API route the pages call is re-checked by
 * RequireRole on the Phoenix side, so even if someone forged a route
 * change here, the backend would still return 403. See
 * backend/lib/cybersentinel_web/plugs/require_role.ex.
 */
export function ProtectedRoute({
  roles,
  children
}: {
  roles?: Role[];
  children: JSX.Element;
}) {
  const { user, loading } = useAuth();

  if (loading) return <div className="p-8 text-slate-400">Loading…</div>;
  if (!user) return <Navigate to="/login" replace />;
  if (roles && !roles.includes(user.role)) return <Navigate to={homeFor(user.role)} replace />;

  return children;
}

export function homeFor(role: Role) {
  switch (role) {
    case "administrator":
      return "/admin/dashboard";
    case "security_analyst":
      return "/analyst/dashboard";
    case "manager":
      return "/manager/dashboard";
  }
}
