import { useEffect, useState } from "react";
import { Layout, StatCard } from "../../components/Layout";
import { api } from "../../api/client";

interface Stats {
  total_users: number;
  active_users: number;
  security_analysts: number;
  managers: number;
  active_detection_rules: number;
  total_alerts: number;
  active_incidents: number;
}

const NAV = [
  { to: "/admin/dashboard", label: "Dashboard" },
  { to: "/admin/users", label: "Users" },
  { to: "/admin/detection-rules", label: "Detection Rules" },
  { to: "/admin/audit-logs", label: "Audit Logs" },
  { to: "/admin/profile", label: "Profile" }
];

export default function AdminDashboard() {
  const [stats, setStats] = useState<Stats | null>(null);

  useEffect(() => {
    api.get<Stats>("/dashboard/stats").then((r) => setStats(r.data));
  }, []);

  return (
    <Layout title="Administrator" nav={NAV}>
      <h1 className="text-lg font-semibold mb-4">Admin Dashboard</h1>
      {stats && (
        <div className="space-y-8">
          <section aria-labelledby="admin-accounts-heading">
            <h2 id="admin-accounts-heading" className="cs-section-title">Users &amp; accounts</h2>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
              <StatCard label="Total Users" value={stats.total_users} />
              <StatCard label="Active Users" value={stats.active_users} tone="emerald" />
              <StatCard label="Security Analysts" value={stats.security_analysts} />
              <StatCard label="Managers" value={stats.managers} />
            </div>
          </section>
          <section aria-labelledby="admin-operations-heading">
            <h2 id="admin-operations-heading" className="cs-section-title">Security operations</h2>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-3">
              <StatCard label="Active Detection Rules" value={stats.active_detection_rules} tone="emerald" />
              <StatCard label="Total Alerts" value={stats.total_alerts} tone="cyan" />
              <StatCard label="Active Incidents" value={stats.active_incidents} tone="orange" />
            </div>
          </section>
        </div>
      )}
    </Layout>
  );
}

export { NAV as ADMIN_NAV };
