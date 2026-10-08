import { useEffect, useState } from "react";
import { Layout, StatCard } from "../../components/Layout";
import { api } from "../../api/client";

interface Stats {
  critical_alerts: number;
  high_alerts: number;
  medium_alerts: number;
  low_alerts: number;
  open_incidents: number;
  investigating_incidents: number;
  resolved_incidents: number;
  events_today: number;
}

const NAV = [
  { to: "/analyst/dashboard", label: "Dashboard" },
  { to: "/analyst/simulator", label: "Security Event Simulator" },
  { to: "/analyst/events", label: "Security Events" },
  { to: "/analyst/alerts", label: "Alerts" },
  { to: "/analyst/incidents", label: "Incidents" },
  { to: "/analyst/profile", label: "Profile" }
];

export default function AnalystDashboard() {
  const [stats, setStats] = useState<Stats | null>(null);

  useEffect(() => {
    api.get<Stats>("/dashboard/stats").then((r) => setStats(r.data));
  }, []);

  return (
    <Layout title="Security Analyst" nav={NAV}>
      <h1 className="text-lg font-semibold mb-4">Analyst Dashboard</h1>
      {stats && (
        <div className="space-y-8">
          <section aria-labelledby="analyst-alerts-heading">
            <div className="mb-3 flex flex-wrap items-end justify-between gap-3">
              <div>
                <h2 id="analyst-alerts-heading" className="cs-section-title mb-0">Alert severity</h2>
                <p className="text-xs text-slate-400">Current alerts by severity</p>
              </div>
              <div className="flex flex-wrap items-center gap-x-3 gap-y-2 text-xs text-slate-400" aria-label="Alert severity distribution">
                <span><i className="mr-1.5 inline-block h-2 w-2 rounded-full bg-severity-critical" />Critical</span>
                <span><i className="mr-1.5 inline-block h-2 w-2 rounded-full bg-severity-high" />High</span>
                <span><i className="mr-1.5 inline-block h-2 w-2 rounded-full bg-severity-medium" />Medium</span>
                <span><i className="mr-1.5 inline-block h-2 w-2 rounded-full bg-severity-low" />Low</span>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
              <StatCard label="Critical Alerts" value={stats.critical_alerts} tone="red" />
              <StatCard label="High Alerts" value={stats.high_alerts} tone="orange" />
              <StatCard label="Medium Alerts" value={stats.medium_alerts} tone="yellow" />
              <StatCard label="Low Alerts" value={stats.low_alerts} tone="emerald" />
            </div>
            <div className="mt-3 flex h-1.5 overflow-hidden rounded-full bg-slate-800" role="img" aria-label={`Alert severity distribution from existing counts: ${stats.critical_alerts} critical, ${stats.high_alerts} high, ${stats.medium_alerts} medium, ${stats.low_alerts} low`}>
              {[
                [stats.critical_alerts, "bg-severity-critical"],
                [stats.high_alerts, "bg-severity-high"],
                [stats.medium_alerts, "bg-severity-medium"],
                [stats.low_alerts, "bg-severity-low"]
              ].map(([count, color], index) => {
                const total = stats.critical_alerts + stats.high_alerts + stats.medium_alerts + stats.low_alerts;
                const width = total > 0 ? `${(Number(count) / total) * 100}%` : "0%";
                return <span key={index} className={String(color)} style={{ width }} />;
              })}
            </div>
          </section>
          <section aria-labelledby="analyst-incidents-heading">
            <h2 id="analyst-incidents-heading" className="cs-section-title">Incident status &amp; activity</h2>
            <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
              <StatCard label="Open Incidents" value={stats.open_incidents} />
              <StatCard label="Investigating Incidents" value={stats.investigating_incidents} tone="cyan" />
              <StatCard label="Resolved Incidents" value={stats.resolved_incidents} tone="emerald" />
              <StatCard label="Events Today" value={stats.events_today} tone="cyan" />
            </div>
          </section>
        </div>
      )}
      <div className="cs-simulator-prompt mt-8 rounded-lg border border-emerald-500/20 bg-emerald-500/5 p-4 text-sm text-slate-300">
        Start the demo flow from <span className="text-emerald-400">Security Event Simulator</span> — generate 5
        failed logins from the same IP to trigger a brute-force alert.
      </div>
    </Layout>
  );
}

export { NAV as ANALYST_NAV };
