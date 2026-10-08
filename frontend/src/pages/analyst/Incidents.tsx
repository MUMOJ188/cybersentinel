import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Layout, SeverityBadge, StatusBadge } from "../../components/Layout";
import { ANALYST_NAV } from "./Dashboard";
import { api } from "../../api/client";
import type { Incident } from "../../types";

export default function Incidents() {
  const [incidents, setIncidents] = useState<Incident[]>([]);

  useEffect(() => {
    api.get("/incidents").then((r) => setIncidents(r.data.incidents));
  }, []);

  return (
    <Layout title="Security Analyst" nav={ANALYST_NAV}>
      <h1 className="text-lg font-semibold mb-4">Incidents</h1>
      <div className="space-y-2">
        {incidents.map((i) => (
          <Link
            key={i.id}
            to={`/analyst/incidents/${i.id}`}
            className="block bg-slate-900 border border-slate-800 hover:border-emerald-700 rounded-lg p-4"
          >
            <div className="flex items-center gap-2 mb-1">
              <span className="text-xs text-slate-500">{i.incident_number}</span>
              <SeverityBadge severity={i.severity} />
              <StatusBadge status={i.status} />
            </div>
            <div className="text-sm font-medium">{i.title}</div>
            <div className="text-xs text-slate-600 mt-1">
              Assigned: {i.assigned_analyst?.username ?? "unassigned"} · {new Date(i.inserted_at).toLocaleString()}
            </div>
          </Link>
        ))}
        {incidents.length === 0 && <div className="text-slate-600 text-sm">No incidents yet.</div>}
      </div>
    </Layout>
  );
}
