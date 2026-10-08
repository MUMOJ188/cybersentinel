import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { Layout, SeverityBadge, StatusBadge } from "../../components/Layout";
import { ANALYST_NAV } from "./Dashboard";
import { api } from "../../api/client";
import type { Incident } from "../../types";

const STATUS_FLOW = ["new", "investigating", "contained", "resolved"];
const ACTION_TYPES = [
  "account_locked",
  "password_reset_requested",
  "ip_blocked",
  "device_isolated",
  "access_revoked",
  "investigation_completed"
];

export default function IncidentDetail() {
  const { id } = useParams<{ id: string }>();
  const [incident, setIncident] = useState<Incident | null>(null);
  const [investigationId, setInvestigationId] = useState<string | null>(null);
  const [note, setNote] = useState("");
  const [actionType, setActionType] = useState(ACTION_TYPES[0]);
  const [actionDescription, setActionDescription] = useState("");
  const [resolutionNotes, setResolutionNotes] = useState("");

  async function reload() {
    const { data } = await api.get(`/incidents/${id}`);
    setIncident(data.incident);
    if (data.incident.investigations?.length > 0) {
      setInvestigationId(data.incident.investigations[0].id);
    }
  }

  useEffect(() => {
    reload();
  }, [id]);

  if (!incident) return <Layout title="Security Analyst" nav={ANALYST_NAV}>Loading…</Layout>;

  async function startInvestigation() {
    const { data } = await api.post("/investigations", { incident_id: id });
    setInvestigationId(data.investigation.id);
    reload();
  }

  async function addNote() {
    if (!investigationId || !note.trim()) return;
    await api.post(`/investigations/${investigationId}/notes`, { note });
    setNote("");
    reload();
  }

  async function recordAction() {
    await api.post("/response-actions", { incident_id: id, action_type: actionType, description: actionDescription });
    setActionDescription("");
    reload();
  }

  async function setStatus(status: string) {
    await api.put(`/incidents/${id}`, { status, resolution_notes: status === "resolved" ? resolutionNotes : undefined });
    reload();
  }

  return (
    <Layout title="Security Analyst" nav={ANALYST_NAV}>
      <div className="flex items-center gap-2 mb-1">
        <span className="text-xs text-slate-500">{incident.incident_number}</span>
        <SeverityBadge severity={incident.severity} />
        <StatusBadge status={incident.status} />
      </div>
      <h1 className="text-lg font-semibold mb-4">{incident.title}</h1>

      <div className="bg-slate-900 border border-slate-800 rounded-lg p-4 mb-6">
        <div className="mb-4 flex flex-wrap items-center justify-between gap-2">
          <div className="text-sm font-medium text-slate-200">Status workflow</div>
          <StatusBadge status={incident.status} />
        </div>
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-4" role="group" aria-label="Set incident status">
          {STATUS_FLOW.map((s) => (
            <button
              key={s}
              onClick={() => setStatus(s)}
              disabled={incident.status === s}
              aria-pressed={incident.status === s}
              className={`flex min-h-11 min-w-0 items-center gap-2 rounded-md border px-3 py-2 text-left text-xs capitalize transition-colors disabled:cursor-default ${
                incident.status === s
                  ? {
                      new: "border-slate-500 bg-slate-700/60 text-slate-50",
                      investigating: "border-cyan-400/50 bg-cyan-400/10 text-cyan-200",
                      contained: "border-amber-400/50 bg-amber-400/10 text-amber-200",
                      resolved: "border-emerald-400/50 bg-emerald-400/10 text-emerald-200"
                    }[s]
                  : "border-slate-700 bg-slate-800/70 text-slate-300 hover:border-slate-500 hover:bg-slate-800"
              }`}
            >
              <span className="grid h-5 w-5 shrink-0 place-items-center rounded-full border border-current/40 font-mono-data text-[10px]">
                {STATUS_FLOW.indexOf(s) + 1}
              </span>
              <span className="truncate">{s}</span>
            </button>
          ))}
        </div>
        {incident.status !== "resolved" && (
          <div className="mt-3">
            <textarea
              placeholder="Resolution notes (used when marking resolved)"
              className="w-full px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
              value={resolutionNotes}
              onChange={(e) => setResolutionNotes(e.target.value)}
            />
          </div>
        )}
      </div>

      <div className="grid md:grid-cols-2 gap-6">
        <div className="bg-slate-900 border border-slate-800 rounded-lg p-4">
          <div className="text-sm text-slate-400 mb-3">Investigation</div>
          {!investigationId ? (
            <button onClick={startInvestigation} className="text-xs bg-emerald-600 hover:bg-emerald-500 rounded px-3 py-1.5">
              Start Investigation
            </button>
          ) : (
            <>
              <div className="space-y-2 mb-3 max-h-48 overflow-y-auto">
                {incident.investigations?.[0]?.notes.map((n) => (
                  <div key={n.id} className="text-sm bg-slate-800 rounded p-2">
                    {n.note}
                    <div className="text-xs text-slate-600">{new Date(n.inserted_at).toLocaleString()}</div>
                  </div>
                ))}
              </div>
              <div className="flex gap-2">
                <input
                  className="flex-1 px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
                  placeholder="Add investigation note…"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                />
                <button onClick={addNote} className="text-xs bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded px-3 py-2">
                  Add
                </button>
              </div>
            </>
          )}
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-lg p-4">
          <div className="text-sm text-slate-400 mb-3">Response actions</div>
          <div className="space-y-2 mb-3 max-h-48 overflow-y-auto">
            {incident.response_actions?.map((a) => (
              <div key={a.id} className="text-sm bg-slate-800 rounded p-2">
                <span className="text-emerald-400">{a.action_type.replace(/_/g, " ")}</span>
                {a.description && <div className="text-slate-400 text-xs">{a.description}</div>}
              </div>
            ))}
          </div>
          <select
            className="w-full mb-2 px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
            value={actionType}
            onChange={(e) => setActionType(e.target.value)}
          >
            {ACTION_TYPES.map((t) => (
              <option key={t} value={t}>
                {t.replace(/_/g, " ")}
              </option>
            ))}
          </select>
          <input
            className="w-full mb-2 px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
            placeholder="Description (optional)"
            value={actionDescription}
            onChange={(e) => setActionDescription(e.target.value)}
          />
          <button onClick={recordAction} className="text-xs bg-emerald-600 hover:bg-emerald-500 rounded px-3 py-1.5">
            Record Action
          </button>
          <div className="text-[11px] text-slate-600 mt-2">
            Recorded only — this does not contact a real firewall, IAM system, or device.
          </div>
        </div>
      </div>
    </Layout>
  );
}
