import { useEffect, useState } from "react";
import { Layout, StatCard } from "../../components/Layout";
import { api } from "../../api/client";

interface Stats {
  total_security_events: number;
  total_alerts: number;
  active_incidents: number;
  resolved_incidents: number;
  critical_incidents: number;
  high_incidents: number;
  average_response_time_seconds: number | null;
}

const NAV = [
  { to: "/manager/dashboard", label: "Dashboard" },
  { to: "/manager/incidents", label: "Incidents" },
  { to: "/manager/alerts", label: "Alerts" },
  { to: "/manager/reports", label: "Reports" },
  { to: "/manager/trends", label: "Security Trends" },
  { to: "/manager/profile", label: "Profile" }
];

function formatDuration(seconds: number | null) {
  if (seconds == null) return "—";
  const h = Math.floor(seconds / 3600);
  const m = Math.round((seconds % 3600) / 60);
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
}

export default function ManagerDashboard() {
  const [stats, setStats] = useState<Stats | null>(null);

  useEffect(() => {
    api.get<Stats>("/dashboard/stats").then((r) => setStats(r.data));
  }, []);

  return (
    <Layout title="Manager" nav={NAV}>
      <h1 className="text-lg font-semibold mb-4">Manager Dashboard</h1>
      {stats && (
        <div className="grid grid-cols-1 gap-7 md:grid-cols-2 xl:grid-cols-4">
          <section className="md:col-span-1 xl:col-span-2" aria-labelledby="manager-volume-heading">
            <h2 id="manager-volume-heading" className="cs-section-title">Operational volume</h2>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <StatCard label="Total Security Events" value={stats.total_security_events} tone="cyan" />
              <StatCard label="Total Alerts" value={stats.total_alerts} tone="emerald" />
            </div>
          </section>
          <section className="md:col-span-1 xl:col-span-2" aria-labelledby="manager-outcomes-heading">
            <h2 id="manager-outcomes-heading" className="cs-section-title">Incident outcomes</h2>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <StatCard label="Active Incidents" value={stats.active_incidents} tone="orange" />
              <StatCard label="Resolved Incidents" value={stats.resolved_incidents} tone="emerald" />
            </div>
          </section>
          <section className="md:col-span-1 xl:col-span-2" aria-labelledby="manager-risk-heading">
            <h2 id="manager-risk-heading" className="cs-section-title">High-priority risk</h2>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <StatCard label="Critical Incidents" value={stats.critical_incidents} tone="red" />
              <StatCard label="High Incidents" value={stats.high_incidents} tone="orange" />
            </div>
          </section>
          <section className="md:col-span-1 xl:col-span-2" aria-labelledby="manager-response-heading">
            <h2 id="manager-response-heading" className="cs-section-title">Response performance</h2>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <StatCard label="Average Response Time" value={formatDuration(stats.average_response_time_seconds)} tone="cyan" />
            </div>
          </section>
        </div>
      )}
    </Layout>
  );
}

export { NAV as MANAGER_NAV };
