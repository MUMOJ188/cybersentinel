import { useEffect, useState } from "react";
import { Layout, SeverityBadge, StatusBadge } from "../../components/Layout";
import { MANAGER_NAV } from "./Dashboard";
import { api } from "../../api/client";
import type { Incident } from "../../types";

export default function ManagerIncidents() {
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [selected, setSelected] = useState<Incident | null>(null);

  useEffect(() => {
    api.get("/manager/incidents").then((r) => setIncidents(r.data.incidents));
  }, []);

  async function open(id: string) {
    const { data } = await api.get(`/manager/incidents/${id}`);
    setSelected(data.incident);
  }

  return (
    <Layout title="Manager" nav={MANAGER_NAV}>
      <h1 className="text-lg font-semibold mb-4">Incidents</h1>
      <div className="grid md:grid-cols-2 gap-6">
        <div className="space-y-2">
          {incidents.map((i) => (
            <button
              key={i.id}
              onClick={() => open(i.id)}
              aria-pressed={selected?.id === i.id}
              className={`block w-full rounded-lg border p-4 text-left transition-colors ${selected?.id === i.id ? "border-emerald-600/70 bg-emerald-500/5" : "bg-slate-900 border-slate-800 hover:border-emerald-700"}`}
            >
              <div className="flex items-center gap-2 mb-1">
                <span className="text-xs text-slate-500">{i.incident_number}</span>
                <SeverityBadge severity={i.severity} />
                <StatusBadge status={i.status} />
              </div>
              <div className="text-sm font-medium">{i.title}</div>
              <div className="text-xs text-slate-600 mt-1">Analyst: {i.assigned_analyst?.username ?? "unassigned"}</div>
            </button>
          ))}
        </div>

        {selected && (
          <div className="bg-slate-900 border border-slate-800 rounded-lg p-4 h-fit">
            <div className="flex items-center gap-2 mb-2">
              <SeverityBadge severity={selected.severity} />
              <StatusBadge status={selected.status} />
            </div>
            <div className="text-sm font-medium mb-2">{selected.title}</div>
            <div className="text-sm text-slate-400 mb-3">{selected.description}</div>
            {selected.resolution_notes && (
              <div className="text-sm mb-3">
                <span className="text-slate-500">Resolution: </span>
                {selected.resolution_notes}
              </div>
            )}
            <div className="text-xs text-slate-500 mb-1">Response actions:</div>
            {selected.response_actions?.map((a) => (
              <div key={a.id} className="text-xs text-slate-400">
                • {a.action_type.replace(/_/g, " ")}
              </div>
            ))}
          </div>
        )}
      </div>
    </Layout>
  );
}
