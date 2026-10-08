import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider, useAuth } from "./context/AuthContext";
import { ProtectedRoute, homeFor } from "./routes/ProtectedRoute";

import Login from "./pages/Login";
import Register from "./pages/Register";
import ForgotPassword from "./pages/ForgotPassword";
import ResetPassword from "./pages/ResetPassword";
import Profile from "./pages/Profile";

import AdminDashboard, { ADMIN_NAV } from "./pages/admin/Dashboard";
import AdminUsers from "./pages/admin/Users";
import AdminDetectionRules from "./pages/admin/DetectionRules";
import AdminAuditLogs from "./pages/admin/AuditLogs";

import AnalystDashboard, { ANALYST_NAV } from "./pages/analyst/Dashboard";
import Simulator from "./pages/analyst/Simulator";
import AnalystEvents from "./pages/analyst/Events";
import AnalystAlerts from "./pages/analyst/Alerts";
import AnalystIncidents from "./pages/analyst/Incidents";
import IncidentDetail from "./pages/analyst/IncidentDetail";

import ManagerDashboard, { MANAGER_NAV } from "./pages/manager/Dashboard";
import ManagerIncidents from "./pages/manager/Incidents";
import ManagerAlerts from "./pages/manager/Alerts";
import ManagerReports from "./pages/manager/Reports";
import ManagerTrends from "./pages/manager/Trends";

function RootRedirect() {
  const { user, loading } = useAuth();
  if (loading) return null;
  return <Navigate to={user ? homeFor(user.role) : "/login"} replace />;
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/" element={<RootRedirect />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/forgot-password" element={<ForgotPassword />} />
          <Route path="/reset-password" element={<ResetPassword />} />

          {/* Administrator */}
          <Route path="/admin/dashboard" element={<ProtectedRoute roles={["administrator"]}><AdminDashboard /></ProtectedRoute>} />
          <Route path="/admin/users" element={<ProtectedRoute roles={["administrator"]}><AdminUsers /></ProtectedRoute>} />
          <Route path="/admin/detection-rules" element={<ProtectedRoute roles={["administrator"]}><AdminDetectionRules /></ProtectedRoute>} />
          <Route path="/admin/audit-logs" element={<ProtectedRoute roles={["administrator"]}><AdminAuditLogs /></ProtectedRoute>} />
          <Route path="/admin/profile" element={<ProtectedRoute roles={["administrator"]}><Profile title="Administrator" nav={ADMIN_NAV} /></ProtectedRoute>} />

          {/* Security Analyst */}
          <Route path="/analyst/dashboard" element={<ProtectedRoute roles={["security_analyst", "administrator"]}><AnalystDashboard /></ProtectedRoute>} />
          <Route path="/analyst/simulator" element={<ProtectedRoute roles={["security_analyst", "administrator"]}><Simulator /></ProtectedRoute>} />
          <Route path="/analyst/events" element={<ProtectedRoute roles={["security_analyst", "administrator"]}><AnalystEvents /></ProtectedRoute>} />
          <Route path="/analyst/alerts" element={<ProtectedRoute roles={["security_analyst", "administrator"]}><AnalystAlerts /></ProtectedRoute>} />
          <Route path="/analyst/incidents" element={<ProtectedRoute roles={["security_analyst", "administrator"]}><AnalystIncidents /></ProtectedRoute>} />
          <Route path="/analyst/incidents/:id" element={<ProtectedRoute roles={["security_analyst", "administrator"]}><IncidentDetail /></ProtectedRoute>} />
          <Route path="/analyst/profile" element={<ProtectedRoute roles={["security_analyst", "administrator"]}><Profile title="Security Analyst" nav={ANALYST_NAV} /></ProtectedRoute>} />

          {/* Manager */}
          <Route path="/manager/dashboard" element={<ProtectedRoute roles={["manager"]}><ManagerDashboard /></ProtectedRoute>} />
          <Route path="/manager/incidents" element={<ProtectedRoute roles={["manager"]}><ManagerIncidents /></ProtectedRoute>} />
          <Route path="/manager/alerts" element={<ProtectedRoute roles={["manager"]}><ManagerAlerts /></ProtectedRoute>} />
          <Route path="/manager/reports" element={<ProtectedRoute roles={["manager"]}><ManagerReports /></ProtectedRoute>} />
          <Route path="/manager/trends" element={<ProtectedRoute roles={["manager"]}><ManagerTrends /></ProtectedRoute>} />
          <Route path="/manager/profile" element={<ProtectedRoute roles={["manager"]}><Profile title="Manager" nav={MANAGER_NAV} /></ProtectedRoute>} />

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
