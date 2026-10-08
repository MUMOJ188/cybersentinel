import { FormEvent, useEffect, useState } from "react";
import { Layout } from "../../components/Layout";
import { ADMIN_NAV } from "./Dashboard";
import { api } from "../../api/client";

interface Rule {
  id: string;
  name: string;
  event_type: string;
  threshold: number;
  time_window_seconds: number;
  severity: string;
  description: string | null;
  enabled: boolean;
}

const EVENT_TYPES = [
  "failed_login",
  "port_scan",
  "suspicious_ip",
  "large_data_transfer",
  "access_denied",
  "unknown_device_login"
];

export default function DetectionRules() {
  const [rules, setRules] = useState<Rule[]>([]);
  const [form, setForm] = useState({
    name: "",
    event_type: EVENT_TYPES[0],
    threshold: 5,
    time_window_seconds: 300,
    severity: "high",
    description: ""
  });

  async function reload() {
    const { data } = await api.get("/admin/detection-rules");
    setRules(data.rules);
  }

  useEffect(() => {
    reload();
  }, []);

  async function toggleEnabled(rule: Rule) {
    await api.put(`/admin/detection-rules/${rule.id}`, { enabled: !rule.enabled });
    reload();
  }

  async function handleCreate(e: FormEvent) {
    e.preventDefault();
    await api.post("/admin/detection-rules", form);
    setForm({ ...form, name: "", description: "" });
    reload();
  }

  return (
    <Layout title="Administrator" nav={ADMIN_NAV}>
      <h1 className="text-lg font-semibold mb-4">Detection Rules</h1>

      <div className="space-y-2 mb-8">
        {rules.map((r) => (
          <div key={r.id} className="bg-slate-900 border border-slate-800 rounded-lg flex flex-col items-start justify-between gap-3 p-4 sm:flex-row sm:items-center">
            <div className="min-w-0">
              <div className="text-sm font-medium">{r.name}</div>
              <div className="text-xs text-slate-500">
                {r.event_type} · threshold {r.threshold} · window {r.time_window_seconds}s · {r.severity}
              </div>
            </div>
            <button
              onClick={() => toggleEnabled(r)}
              className={`text-xs rounded px-3 py-1.5 border ${
                r.enabled ? "border-emerald-700 text-emerald-400" : "border-slate-700 text-slate-500"
              }`}
            >
              {r.enabled ? "Enabled" : "Disabled"}
            </button>
          </div>
        ))}
      </div>

      <form onSubmit={handleCreate} className="bg-slate-900 border border-slate-800 rounded-lg p-4 max-w-md space-y-2">
        <div className="text-sm text-slate-400">New rule</div>
        <input
          placeholder="Name"
          className="w-full px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
          required
        />
        <select
          className="w-full px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
          value={form.event_type}
          onChange={(e) => setForm({ ...form, event_type: e.target.value })}
        >
          {EVENT_TYPES.map((t) => (
            <option key={t} value={t}>
              {t}
            </option>
          ))}
        </select>
        <div className="grid grid-cols-2 gap-2">
          <input
            type="number"
            placeholder="Threshold"
            className="w-full px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
            value={form.threshold}
            onChange={(e) => setForm({ ...form, threshold: Number(e.target.value) })}
          />
          <input
            type="number"
            placeholder="Window (seconds)"
            className="w-full px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
            value={form.time_window_seconds}
            onChange={(e) => setForm({ ...form, time_window_seconds: Number(e.target.value) })}
          />
        </div>
        <select
          className="w-full px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
          value={form.severity}
          onChange={(e) => setForm({ ...form, severity: e.target.value })}
        >
          <option value="low">low</option>
          <option value="medium">medium</option>
          <option value="high">high</option>
          <option value="critical">critical</option>
        </select>
        <textarea
          placeholder="Description"
          className="w-full px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
          value={form.description}
          onChange={(e) => setForm({ ...form, description: e.target.value })}
        />
        <button className="bg-emerald-600 hover:bg-emerald-500 rounded px-4 py-2 text-sm font-medium">
          Create Rule
        </button>
      </form>
    </Layout>
  );
}
