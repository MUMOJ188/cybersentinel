import { FormEvent, useState } from "react";
import { Layout } from "../components/Layout";
import { useAuth } from "../context/AuthContext";
import { api } from "../api/client";
import type { NavItem } from "../routes/navTypes";

export default function Profile({ title, nav }: { title: string; nav: NavItem[] }) {
  const { user } = useAuth();
  const [password, setPassword] = useState("");
  const [passwordConfirmation, setPasswordConfirmation] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setMessage(null);
    setError(null);
    try {
      await api.post("/auth/password-reset", { password, password_confirmation: passwordConfirmation });
      setMessage("Password updated.");
      setPassword("");
      setPasswordConfirmation("");
    } catch (err: any) {
      setError(JSON.stringify(err.response?.data?.errors ?? "Failed"));
    }
  }

  return (
    <Layout title={title} nav={nav}>
      <h1 className="text-lg font-semibold mb-4">Profile</h1>
      <div className="bg-slate-900 border border-slate-800 rounded-lg p-4 mb-6 max-w-md text-sm space-y-1">
        <div><span className="text-slate-500">Full name:</span> {user?.full_name}</div>
        <div><span className="text-slate-500">Username:</span> {user?.username}</div>
        <div><span className="text-slate-500">Email:</span> {user?.email}</div>
        <div><span className="text-slate-500">Role:</span> {user?.role}</div>
      </div>

      <form onSubmit={handleSubmit} className="bg-slate-900 border border-slate-800 rounded-lg p-4 max-w-md">
        <div className="text-sm text-slate-400 mb-3">Reset password</div>
        {message && <div className="text-emerald-400 text-xs mb-2">{message}</div>}
        {error && <div className="text-red-400 text-xs mb-2">{error}</div>}
        <input
          type="password"
          placeholder="New password"
          className="w-full mb-2 px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
        <input
          type="password"
          placeholder="Confirm new password"
          className="w-full mb-3 px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
          value={passwordConfirmation}
          onChange={(e) => setPasswordConfirmation(e.target.value)}
          required
        />
        <button className="bg-emerald-600 hover:bg-emerald-500 rounded px-4 py-2 text-sm font-medium">
          Update Password
        </button>
      </form>
    </Layout>
  );
}
