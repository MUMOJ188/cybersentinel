import { useEffect, useState } from "react";
import { Layout, SeverityBadge, StatusBadge } from "../../components/Layout";
import { ANALYST_NAV } from "./Dashboard";
import { api } from "../../api/client";
import { useAuth } from "../../context/AuthContext";
import { useAlertsSocket } from "../../hooks/useAlertsSocket";
import type { Alert } from "../../types";
import { useNavigate } from "react-router-dom";

export default function Alerts() {
  const { token } = useAuth();
  const { liveAlerts } = useAlertsSocket(token);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const navigate = useNavigate();

  async function reload() {
    const { data } = await api.get("/alerts");
    setAlerts(data.alerts);
  }

  useEffect(() => {
    reload();
  }, []);

  // Merge the live-pushed alerts in at the top (dedup by id) so the list
  // updates instantly when the DetectionEngine fires, without a full reload.
  const merged = [...liveAlerts, ...alerts].filter(
    (a, i, arr) => arr.findIndex((b) => b.id === a.id) === i
  );

  async function acknowledge(id: string) {
    await api.post(`/alerts/${id}/acknowledge`);
    reload();
  }

  async function createIncident(alertId: string) {
    const { data } = await api.post("/incidents", { alert_id: alertId });
    navigate(`/analyst/incidents/${data.incident.id}`);
  }

  return (
    <Layout title="Security Analyst" nav={ANALYST_NAV}>
      <h1 className="text-lg font-semibold mb-4">Alerts {liveAlerts.length > 0 && `(${liveAlerts.length} new)`}</h1>
      <div className="space-y-2">
        {merged.map((a) => (
          <div key={a.id} className="bg-slate-900 border border-slate-800 rounded-lg p-4 flex flex-col items-start justify-between gap-4 sm:flex-row">
            <div className="min-w-0">
              <div className="flex items-center gap-2 mb-1">
                <SeverityBadge severity={a.severity} />
                <StatusBadge status={a.status} />
                <span className="text-sm font-medium">{a.alert_type.replace(/_/g, " ")}</span>
              </div>
              <div className="text-sm text-slate-400">{a.description}</div>
              <div className="mt-1 text-xs text-slate-400">
                {a.source_ip && <span className="font-mono-data">IP: {a.source_ip} · </span>}
                <span className="font-mono-data">{new Date(a.inserted_at ?? Date.now()).toLocaleString()}</span>
              </div>
            </div>
            <div className="flex w-full flex-wrap gap-2 sm:w-auto sm:shrink-0">
              {a.status === "new" && (
                <button
                  onClick={() => acknowledge(a.id)}
                  className="text-xs bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded px-3 py-1.5"
                >
                  Acknowledge
                </button>
              )}
              <button
                onClick={() => createIncident(a.id)}
                className="text-xs bg-emerald-600 hover:bg-emerald-500 rounded px-3 py-1.5"
              >
                Create Incident
              </button>
            </div>
          </div>
        ))}
        {merged.length === 0 && <div className="text-slate-600 text-sm">No alerts yet.</div>}
      </div>
    </Layout>
  );
}
