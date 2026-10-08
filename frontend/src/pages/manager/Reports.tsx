import { useEffect, useState } from "react";
import { Layout, StatCard } from "../../components/Layout";
import { MANAGER_NAV } from "./Dashboard";
import { api } from "../../api/client";
import { generateReportPdf, type ReportExport } from "../../utils/generateReportPdf";

interface Summary {
  total_security_events: number;
  total_alerts: number;
  incidents_by_status: Record<string, number>;
  incidents_by_severity: Record<string, number>;
  alerts_by_severity: Record<string, number>;
  average_response_time_seconds: number | null;
}

const PERIODS: { key: "daily" | "weekly" | "monthly"; label: string }[] = [
  { key: "daily", label: "Daily" },
  { key: "weekly", label: "Weekly" },
  { key: "monthly", label: "Monthly" }
];

function fmtDuration(seconds: number | null) {
  if (seconds == null) return "N/A";
  const h = Math.floor(seconds / 3600);
  const m = Math.round((seconds % 3600) / 60);
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
}

export default function Reports() {
  const [summary, setSummary] = useState<Summary | null>(null);
  const [summaryError, setSummaryError] = useState<string | null>(null);

  const [selectedPeriod, setSelectedPeriod] = useState<"daily" | "weekly" | "monthly" | null>(null);
  const [periodData, setPeriodData] = useState<ReportExport | null>(null);
  const [loadingPeriod, setLoadingPeriod] = useState(false);
  const [periodError, setPeriodError] = useState<string | null>(null);

  useEffect(() => {
    api
      .get("/manager/reports/summary")
      .then((r) => setSummary(r.data))
      .catch(() => setSummaryError("Could not load the report summary. Check that the backend is running and reachable."));
  }, []);

  async function handleSelectPeriod(period: "daily" | "weekly" | "monthly") {
    setSelectedPeriod(period);
    setLoadingPeriod(true);
    setPeriodError(null);
    setPeriodData(null);
    try {
      const { data } = await api.get<ReportExport>("/manager/reports/export", { params: { period } });
      setPeriodData(data);
    } catch (err) {
      setPeriodError("Could not load this report. Try again.");
    } finally {
      setLoadingPeriod(false);
    }
  }

  function handleDownload() {
    if (periodData) generateReportPdf(periodData);
  }

  if (summaryError) {
    return (
      <Layout title="Manager" nav={MANAGER_NAV}>
        <div className="text-red-400 text-sm">{summaryError}</div>
      </Layout>
    );
  }
  if (!summary) return <Layout title="Manager" nav={MANAGER_NAV}>Loading…</Layout>;

  return (
    <Layout title="Manager" nav={MANAGER_NAV}>
      <h1 className="text-lg font-semibold mb-4">Management Report</h1>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-8">
        <StatCard label="Total Events" value={summary.total_security_events} />
        <StatCard label="Total Alerts" value={summary.total_alerts} />
        <StatCard
          label="Avg Response Time"
          value={summary.average_response_time_seconds ? `${Math.round(summary.average_response_time_seconds / 60)}m` : "—"}
        />
      </div>

      <div className="grid md:grid-cols-3 gap-6 mb-8">
        <BreakdownCard title="Incidents by Status" data={summary.incidents_by_status} />
        <BreakdownCard title="Incidents by Severity" data={summary.incidents_by_severity} />
        <BreakdownCard title="Alerts by Severity" data={summary.alerts_by_severity} />
      </div>

      <section className="bg-slate-900 border border-slate-800 rounded-lg p-4 sm:p-5" aria-label="Generate a report">
        <h2 className="text-sm font-semibold text-slate-200 mb-1">Generate a report</h2>
        <p className="text-xs text-slate-500 mb-4">Choose a period to preview its numbers, then download the PDF.</p>

        <div className="flex gap-2 mb-5">
          {PERIODS.map((p) => (
            <button
              key={p.key}
              onClick={() => handleSelectPeriod(p.key)}
              aria-pressed={selectedPeriod === p.key}
              className={`text-xs rounded px-3 py-2 font-medium border transition-colors ${
                selectedPeriod === p.key
                  ? "bg-emerald-600/20 border-emerald-700 text-emerald-400"
                  : "bg-slate-800 border-slate-700 text-slate-300 hover:bg-slate-700"
              }`}
            >
              {p.label}
            </button>
          ))}
        </div>

        {loadingPeriod && <div className="text-slate-500 text-sm">Loading {selectedPeriod} report…</div>}
        {periodError && <div className="text-red-400 text-sm">{periodError}</div>}

        {periodData && !loadingPeriod && (
          <div className="border-t border-slate-800 pt-4">
            <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
              <div>
                <div className="text-sm font-medium text-slate-50">{periodData.period_label} Report Preview</div>
                <div className="font-mono-data text-xs text-slate-500">
                  {new Date(periodData.range_start).toLocaleString()} — {new Date(periodData.range_end).toLocaleString()}
                </div>
              </div>
              <button
                onClick={handleDownload}
                className="text-xs bg-emerald-600 hover:bg-emerald-500 rounded px-4 py-2 font-medium"
              >
                Download PDF
              </button>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <PreviewStat label="Total Events" value={periodData.total_security_events} />
              <PreviewStat label="Total Alerts" value={periodData.total_alerts} />
              <PreviewStat label="Critical Alerts" value={periodData.critical_alerts} />
              <PreviewStat label="High Alerts" value={periodData.high_alerts} />
              <PreviewStat label="New Incidents" value={periodData.new_incidents} />
              <PreviewStat label="Resolved Incidents" value={periodData.resolved_incidents} />
              <PreviewStat label="Avg Response Time" value={fmtDuration(periodData.average_response_time_seconds)} />
              <PreviewStat label="Most Common Alert" value={periodData.most_common_alert_type} />
            </div>
          </div>
        )}
      </section>
    </Layout>
  );
}

function PreviewStat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="bg-slate-800 border border-slate-700 rounded p-3 min-w-0">
      <div className="text-slate-500 text-xs mb-1 truncate">{label}</div>
      <div className="font-mono-data text-slate-50 text-sm font-medium truncate">{value}</div>
    </div>
  );
}

function BreakdownCard({ title, data }: { title: string; data: Record<string, number> }) {
  const max = Math.max(1, ...Object.values(data));
  return (
    <div className="bg-slate-900 border border-slate-800 rounded-lg p-4">
      <h2 className="mb-4 text-sm font-semibold text-slate-200">{title}</h2>
      <div className="space-y-3">
        {Object.entries(data).map(([k, v]) => (
          <div key={k} className="min-w-0">
            <div className="mb-1 flex items-center justify-between gap-3 text-sm">
              <span className="capitalize text-slate-300">{k.replace(/_/g, " ")}</span>
              <span className="font-mono-data text-slate-50">{v}</span>
            </div>
            <div className="h-1.5 overflow-hidden rounded-full bg-slate-800" aria-hidden="true">
              <div className="h-full rounded-full bg-emerald-500" style={{ width: `${(v / max) * 100}%` }} />
            </div>
          </div>
        ))}
        {Object.keys(data).length === 0 && <div className="text-slate-600 text-sm">No data yet.</div>}
      </div>
    </div>
  );
}