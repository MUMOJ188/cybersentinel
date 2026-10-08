import { useEffect, useState } from "react";
import { Layout } from "../../components/Layout";
import { ADMIN_NAV } from "./Dashboard";
import { api } from "../../api/client";

interface LogEntry {
  id: string;
  action: string;
  resource_type: string | null;
  description: string | null;
  ip_address: string | null;
  inserted_at: string;
  user: { username: string } | null;
}

export default function AuditLogs() {
  const [logs, setLogs] = useState<LogEntry[]>([]);

  useEffect(() => {
    api.get("/admin/audit-logs").then((r) => setLogs(r.data.logs));
  }, []);

  return (
    <Layout title="Administrator" nav={ADMIN_NAV}>
      <h1 className="text-lg font-semibold mb-4">Audit Logs</h1>
      <div className="cs-table-wrap">
      <table className="w-full text-sm">
        <thead className="text-slate-500 text-xs uppercase text-left">
          <tr>
            <th className="py-2">Action</th>
            <th>User</th>
            <th>Description</th>
            <th>IP</th>
            <th>Time</th>
          </tr>
        </thead>
        <tbody>
          {logs.map((l) => (
            <tr key={l.id} className="border-t border-slate-800">
              <td className="font-mono-data py-2 text-slate-100">{l.action}</td>
              <td>{l.user?.username ?? "—"}</td>
              <td className="text-slate-400">{l.description}</td>
              <td className="font-mono-data text-slate-400">{l.ip_address}</td>
              <td className="font-mono-data text-slate-400">{new Date(l.inserted_at).toLocaleString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
      </div>
      {logs.length === 0 && <div className="text-slate-600 text-sm mt-4">No audit entries yet.</div>}
    </Layout>
  );
}
