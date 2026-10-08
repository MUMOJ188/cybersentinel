import { useEffect, useState, ReactNode } from "react";
import { NavLink, useLocation, useNavigate } from "react-router-dom";
import {
  Activity,
  Bell,
  FileBarChart2,
  FlaskConical,
  LayoutDashboard,
  LogOut,
  Menu,
  ScrollText,
  ShieldAlert,
  ShieldCheck,
  Siren,
  TrendingUp,
  UserRound,
  Users,
  X
} from "lucide-react";
import { useAuth } from "../context/AuthContext";

interface NavItem {
  to: string;
  label: string;
}

export function Layout({ title, nav, children }: { title: string; nav: NavItem[]; children: ReactNode }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const currentNav = [...nav]
    .sort((a, b) => b.to.length - a.to.length)
    .find((item) => location.pathname === item.to || location.pathname.startsWith(`${item.to}/`));

  useEffect(() => {
    setMobileNavOpen(false);
  }, [location.pathname]);

  function handleLogout() {
    logout();
    navigate("/login");
  }

  return (
    <div className="cs-shell min-h-screen flex">
      {mobileNavOpen && (
        <button
          type="button"
          className="fixed inset-0 z-40 bg-black/65 md:hidden"
          aria-label="Close navigation menu"
          onClick={() => setMobileNavOpen(false)}
        />
      )}
      <aside
        id="primary-navigation"
        className={`cs-sidebar fixed inset-y-0 left-0 z-50 flex w-72 shrink-0 flex-col border-r border-slate-800 bg-[#0E1514] transition-transform duration-200 md:visible md:static md:z-auto md:w-16 md:translate-x-0 lg:w-60 ${mobileNavOpen ? "visible translate-x-0" : "invisible -translate-x-full"}`}
        aria-label={`${title} navigation`}
      >
        <div className="flex h-16 items-center gap-3 border-b border-slate-800 px-4">
          <div className="grid h-9 w-9 shrink-0 place-items-center rounded-md border border-emerald-500/30 bg-emerald-500/10 text-emerald-400">
            <ShieldCheck size={19} strokeWidth={1.8} aria-hidden="true" />
          </div>
          <div className="min-w-0 md:hidden lg:block">
            <div className="truncate text-sm font-semibold tracking-wide text-slate-50">CyberSentinel</div>
            <div className="text-xs text-slate-400">{title}</div>
          </div>
        </div>
        <nav className="flex-1 space-y-1 overflow-y-auto p-2" aria-label="Primary">
          {nav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              title={item.label}
              className={({ isActive }) =>
                `cs-nav-link group relative flex min-h-11 items-center gap-3 rounded-md px-3 py-2 text-sm transition-colors md:justify-center md:px-0 lg:justify-start lg:px-3 ${
                  isActive
                    ? "bg-emerald-500/10 font-medium text-emerald-300 before:absolute before:left-0 before:h-6 before:w-0.5 before:rounded-r before:bg-emerald-400"
                    : "text-slate-300 hover:bg-slate-800 hover:text-slate-50"
                }`
              }
            >
              <NavIcon label={item.label} />
              <span className="md:sr-only lg:not-sr-only">{item.label}</span>
            </NavLink>
          ))}
        </nav>
        <div className="border-t border-slate-800 p-3 text-sm">
          <div className="mb-2 min-w-0 md:hidden lg:block">
            <div className="truncate text-slate-200">{user?.full_name}</div>
            <div className="text-xs capitalize text-slate-400">{user?.role?.replace(/_/g, " ")}</div>
          </div>
          <button
            type="button"
            onClick={handleLogout}
            title="Log out"
            className="flex min-h-10 w-full items-center gap-3 rounded-md px-2 text-left text-sm text-red-300 transition-colors hover:bg-red-400/10 hover:text-red-200 md:justify-center lg:justify-start"
          >
            <LogOut size={17} strokeWidth={1.8} aria-hidden="true" />
            <span className="md:sr-only lg:not-sr-only">Log out</span>
          </button>
        </div>
      </aside>
      <div className="min-w-0 flex-1">
        <header className="cs-topbar sticky top-0 z-30 flex min-h-16 items-center justify-between border-b border-slate-800 bg-slate-950/95 px-4 backdrop-blur sm:px-6 lg:px-8">
          <div className="flex min-w-0 items-center gap-3">
            <button
              type="button"
              className="grid h-10 w-10 shrink-0 place-items-center rounded-md border border-slate-700 bg-slate-900 text-slate-200 hover:bg-slate-800 md:hidden"
              aria-label={mobileNavOpen ? "Close navigation menu" : "Open navigation menu"}
              aria-expanded={mobileNavOpen}
              aria-controls="primary-navigation"
              onClick={() => setMobileNavOpen((open) => !open)}
            >
              {mobileNavOpen ? <X size={19} aria-hidden="true" /> : <Menu size={19} aria-hidden="true" />}
            </button>
            <div className="min-w-0">
              <div className="text-[11px] font-medium uppercase text-slate-400">{title}</div>
              <div className="truncate text-sm font-semibold text-slate-50">{currentNav?.label ?? title}</div>
            </div>
          </div>
          <div className="hidden min-w-0 items-center gap-3 sm:flex">
            <div className="grid h-9 w-9 shrink-0 place-items-center rounded-full border border-slate-700 bg-slate-900 text-xs font-semibold text-emerald-300">
              {user?.full_name?.slice(0, 1).toUpperCase()}
            </div>
            <div className="min-w-0 text-right">
              <div className="max-w-48 truncate text-sm text-slate-200">{user?.full_name}</div>
              <div className="text-xs capitalize text-slate-400">{user?.role?.replace(/_/g, " ")}</div>
            </div>
          </div>
        </header>
        <main className="min-w-0 p-4 sm:p-6 lg:p-8">{children}</main>
      </div>
    </div>
  );
}

function NavIcon({ label }: { label: string }) {
  const iconProps = { size: 18, strokeWidth: 1.8, "aria-hidden": true as const };
  const icons: Record<string, typeof LayoutDashboard> = {
    Dashboard: LayoutDashboard,
    Users,
    "Detection Rules": ShieldCheck,
    "Audit Logs": ScrollText,
    Profile: UserRound,
    "Security Event Simulator": FlaskConical,
    "Security Events": Activity,
    Alerts: Bell,
    Incidents: ShieldAlert,
    Reports: FileBarChart2,
    "Security Trends": TrendingUp
  };
  const Icon = icons[label] ?? Siren;
  return <Icon {...iconProps} className="shrink-0" />;
}

export function StatCard({
  label,
  value,
  tone = "neutral"
}: {
  label: string;
  value: string | number;
  tone?: "neutral" | "emerald" | "yellow" | "orange" | "red" | "cyan";
}) {
  return (
    <div className="cs-panel relative min-w-0 overflow-hidden p-4 sm:p-5">
      <div className={`cs-stat-accent cs-stat-accent-${tone}`} aria-hidden="true" />
      <div className="text-xs font-medium uppercase text-slate-400">{label}</div>
      <div className="font-mono-data mt-2 text-2xl font-semibold leading-none text-slate-50 sm:text-[28px]">{value}</div>
    </div>
  );
}

export function SeverityBadge({ severity }: { severity: string }) {
  const colors: Record<string, string> = {
    low: "border-severity-low/30 bg-severity-low/10 text-severity-low",
    medium: "border-severity-medium/30 bg-severity-medium/10 text-severity-medium",
    high: "border-severity-high/30 bg-severity-high/10 text-severity-high",
    critical: "border-severity-critical/30 bg-severity-critical/10 text-severity-critical"
  };
  return (
    <span className={`inline-flex min-h-6 items-center rounded border px-2 text-[11px] font-semibold uppercase ${colors[severity] ?? "border-slate-700 bg-slate-800 text-slate-200"}`}>
      {severity}
    </span>
  );
}

export function StatusBadge({ status }: { status: string }) {
  const colors: Record<string, string> = {
    new: "border-slate-600 bg-slate-800 text-slate-200",
    investigating: "border-cyan-400/30 bg-cyan-400/10 text-cyan-300",
    contained: "border-amber-400/30 bg-amber-400/10 text-amber-300",
    resolved: "border-emerald-400/30 bg-emerald-400/10 text-emerald-300",
    acknowledged: "border-cyan-400/30 bg-cyan-400/10 text-cyan-300",
    false_positive: "border-slate-600 bg-slate-800 text-slate-300"
  };
  return (
    <span className={`inline-flex min-h-6 items-center rounded border px-2 text-[11px] font-medium capitalize ${colors[status] ?? "border-slate-700 bg-slate-800 text-slate-200"}`}>
      {status.replace(/_/g, " ")}
    </span>
  );
}

