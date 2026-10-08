import { useEffect, useState } from "react";
import { Layout } from "../../components/Layout";
import { MANAGER_NAV } from "./Dashboard";
import { api } from "../../api/client";

interface Trends {
  events_by_day: { date: string; count: number }[];
  alerts_by_day: { date: string; count: number }[];
}

export default function TrendsPage() {
  const [trends, setTrends] = useState<Trends | null>(null);

  useEffect(() => {
    api.get("/manager/reports/trends").then((r) => setTrends(r.data));
  }, []);

  return (
    <Layout title="Manager" nav={MANAGER_NAV}>
      <h1 className="mb-4 text-lg font-semibold text-slate-50">
        Security Trends <span className="text-sm font-normal text-slate-400">(last 14 days)</span>
      </h1>
      {trends && (
        <div className="grid md:grid-cols-2 gap-6">
          <TrendTable title="Events per day" rows={trends.events_by_day} />
          <TrendTable title="Alerts per day" rows={trends.alerts_by_day} />
        </div>
      )}
    </Layout>
  );
}

function TrendTable({ title, rows }: { title: string; rows: { date: string; count: number }[] }) {
  const max = Math.max(1, ...rows.map((r) => r.count));
  return (
    <section className="bg-slate-900 border border-slate-800 rounded-lg p-4 sm:p-5" aria-label={title}>
      <h2 className="mb-4 text-sm font-semibold text-slate-200">{title}</h2>
      <div className="space-y-2">
        {rows.map((r) => (
          <div key={r.date} className="grid grid-cols-[6.5rem_minmax(0,1fr)_2.5rem] items-center gap-3 text-xs">
            <span className="font-mono-data text-slate-400">{r.date}</span>
            <div className="h-2 overflow-hidden rounded-full bg-slate-800" aria-hidden="true">
              <div className="h-full rounded-full bg-emerald-500" style={{ width: `${(r.count / max) * 100}%` }} />
            </div>
            <span className="font-mono-data text-right text-slate-200">{r.count}</span>
          </div>
        ))}
        {rows.length === 0 && <div className="text-slate-600 text-sm">No data yet.</div>}
      </div>
    </section>
  );
}
