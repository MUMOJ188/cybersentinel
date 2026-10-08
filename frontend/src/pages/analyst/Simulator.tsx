import { useState } from "react";
import { Layout } from "../../components/Layout";
import { ANALYST_NAV } from "./Dashboard";
import { api } from "../../api/client";

interface SimResult {
  event: { id: string; event_type: string; description: string };
  alerts_triggered: { id: string; alert_type: string; severity: string; description: string }[];
}

export default function Simulator() {
  const [ip, setIp] = useState("192.168.1.20");
  const [log, setLog] = useState<SimResult[]>([]);
  const [busy, setBusy] = useState(false);

  async function fire(endpoint: string, body: Record<string, unknown> = {}) {
    setBusy(true);
    try {
      const { data } = await api.post<SimResult>(`/simulation/${endpoint}`, body);
      setLog((prev) => [data, ...prev]);
    } finally {
      setBusy(false);
    }
  }

  async function runBruteForceDemo() {
    // Fires 5 failed-login events from the same IP in sequence — this is
    // the exact "DEMO FLOW" scenario: the 5th call is expected to trigger
    // "Possible Brute-Force Attack".
    setBusy(true);
    try {
      for (let i = 0; i < 5; i++) {
        const { data } = await api.post<SimResult>("/simulation/failed-login", { source_ip: ip, username: "admin" });
        setLog((prev) => [data, ...prev]);
      }
    } finally {
      setBusy(false);
    }
  }

  return (
    <Layout title="Security Analyst" nav={ANALYST_NAV}>
      <h1 className="text-lg font-semibold mb-1">Security Event Simulator</h1>
      <p className="text-sm text-slate-500 mb-6">
        Generates safe, database-only test events. Nothing here touches a real network.
      </p>

      <div className="bg-slate-900 border border-slate-800 rounded-lg p-4 mb-6">
        <div className="text-sm text-slate-400 mb-2">Brute-force demo (5 failed logins from one IP)</div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <input
            className="px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm flex-1"
            value={ip}
            onChange={(e) => setIp(e.target.value)}
          />
          <button
            disabled={busy}
            onClick={runBruteForceDemo}
            className="bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 px-4 py-2 rounded text-sm font-medium sm:shrink-0"
          >
            Run 5x Failed Login
          </button>
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-3 mb-8">
        <SimButton label="Failed Login" busy={busy} onClick={() => fire("failed-login", { source_ip: ip })} />
        <SimButton label="Port Scan" busy={busy} onClick={() => fire("port-scan", { source_ip: "10.0.0.66" })} />
        <SimButton label="Suspicious IP" busy={busy} onClick={() => fire("suspicious-ip", {})} />
        <SimButton label="Large Data Transfer" busy={busy} onClick={() => fire("data-transfer", {})} />
        <SimButton label="Access Denied" busy={busy} onClick={() => fire("access-denied", {})} />
        <SimButton label="Unknown Device Login" busy={busy} onClick={() => fire("unknown-device", {})} />
      </div>

      <h2 className="text-sm font-semibold text-slate-400 mb-2">Event Log</h2>
      <div className="space-y-2">
        {log.map((r, i) => (
          <div key={i} className="bg-slate-900 border border-slate-800 rounded p-3 text-sm">
            <div className="text-slate-300">{r.event.description}</div>
            {r.alerts_triggered.length > 0 && (
              <div className="mt-2 space-y-1">
                {r.alerts_triggered.map((a) => (
                  <div key={a.id} className="text-emerald-400 text-xs">
                    ⚠ Alert created: {a.description}
                  </div>
                ))}
              </div>
            )}
          </div>
        ))}
        {log.length === 0 && <div className="text-slate-600 text-sm">No events generated yet.</div>}
      </div>
    </Layout>
  );
}

function SimButton({ label, busy, onClick }: { label: string; busy: boolean; onClick: () => void }) {
  return (
    <button
      disabled={busy}
      onClick={onClick}
      className="bg-slate-800 hover:bg-slate-700 disabled:opacity-50 border border-slate-700 rounded px-3 py-3 text-sm"
    >
      {label}
    </button>
  );
}
