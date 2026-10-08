import { FormEvent, useState } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { api } from "../api/client";

export default function ResetPassword() {
  const [searchParams] = useSearchParams();
  const token = searchParams.get("token") ?? "";
  const navigate = useNavigate();

  const [password, setPassword] = useState("");
  const [passwordConfirmation, setPasswordConfirmation] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await api.post("/auth/reset-password", {
        token,
        password,
        password_confirmation: passwordConfirmation
      });
      navigate("/login", {
        state: { successMessage: "Password reset. Please log in with your new password." }
      });
    } catch (err: any) {
      if (err.response?.status === 422 && err.response?.data?.error === "invalid_or_expired_token") {
        setError("This reset link is invalid or has expired. Request a new one.");
      } else {
        setError("Could not reset your password. Try again.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  if (!token) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-950">
        <div className="w-full max-w-sm bg-slate-900 border border-slate-800 rounded-lg p-6 text-center">
          <p className="text-red-400 text-sm mb-4">Missing or invalid reset link.</p>
          <Link to="/forgot-password" className="text-emerald-400 text-sm">Request a new link</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950">
      <form onSubmit={handleSubmit} className="w-full max-w-sm bg-slate-900 border border-slate-800 rounded-lg p-6">
        <h1 className="text-xl font-bold text-emerald-400 mb-6">Set a new password</h1>

        {error && <div className="bg-red-500/10 text-red-400 text-sm p-2 rounded mb-4">{error}</div>}

        <label className="block text-sm text-slate-400 mb-1">New password</label>
        <input
          type="password"
          className="w-full mb-4 px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />

        <label className="block text-sm text-slate-400 mb-1">Confirm new password</label>
        <input
          type="password"
          className="w-full mb-6 px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
          value={passwordConfirmation}
          onChange={(e) => setPasswordConfirmation(e.target.value)}
          required
        />

        <button
          disabled={submitting}
          className="w-full bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 rounded py-2 text-sm font-medium"
        >
          {submitting ? "Resetting…" : "Reset password"}
        </button>
      </form>
    </div>
  );
}
