import { useEffect, useState } from "react";
import { Layout, SeverityBadge, StatusBadge } from "../../components/Layout";
import { MANAGER_NAV } from "./Dashboard";
import { api } from "../../api/client";
import type { Alert } from "../../types";

export default function ManagerAlerts() {
  const [alerts, setAlerts] = useState<Alert[]>([]);

  useEffect(() => {
    api.get("/manager/alerts").then((r) => setAlerts(r.data.alerts));
  }, []);

  return (
    <Layout title="Manager" nav={MANAGER_NAV}>
      <h1 className="text-lg font-semibold mb-4">Alerts</h1>
      <div className="space-y-2">
        {alerts.map((a) => (
          <div key={a.id} className="bg-slate-900 border border-slate-800 rounded-lg p-4">
            <div className="flex items-center gap-2 mb-1">
              <SeverityBadge severity={a.severity} />
              <StatusBadge status={a.status} />
              <span className="text-sm">{a.alert_type.replace(/_/g, " ")}</span>
            </div>
            <div className="text-xs text-slate-600">{a.source_ip}</div>
          </div>
        ))}
        {alerts.length === 0 && <div className="text-slate-600 text-sm">No alerts yet.</div>}
      </div>
    </Layout>
  );
}
