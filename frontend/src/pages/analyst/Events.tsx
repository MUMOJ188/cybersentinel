import { useEffect, useState } from "react";
import { Layout } from "../../components/Layout";
import { ANALYST_NAV } from "./Dashboard";
import { api } from "../../api/client";
import type { SecurityEvent } from "../../types";

export default function Events() {
  const [events, setEvents] = useState<SecurityEvent[]>([]);

  useEffect(() => {
    api.get("/security-events").then((r) => setEvents(r.data.events));
  }, []);

  return (
    <Layout title="Security Analyst" nav={ANALYST_NAV}>
      <h1 className="text-lg font-semibold mb-4">Security Events</h1>
      <div className="cs-table-wrap">
      <table className="w-full text-sm">
        <thead className="text-slate-500 text-xs uppercase text-left">
          <tr>
            <th className="py-2">Type</th>
            <th>Source IP</th>
            <th>Target</th>
            <th>Description</th>
            <th>Time</th>
          </tr>
        </thead>
        <tbody>
          {events.map((e) => (
            <tr key={e.id} className="border-t border-slate-800">
              <td className="py-2">{e.event_type.replace(/_/g, " ")}</td>
              <td className="font-mono-data">{e.source_ip ?? "—"}</td>
              <td className="font-mono-data">{e.target ?? "—"}</td>
              <td className="text-slate-400">{e.description}</td>
              <td className="font-mono-data text-slate-400">{new Date(e.occurred_at).toLocaleString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
      </div>
      {events.length === 0 && <div className="text-slate-600 text-sm mt-4">No events yet.</div>}
    </Layout>
  );
}
