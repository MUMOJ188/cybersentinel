import { FormEvent, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";

export default function ForgotPassword() {
  const [email, setEmail] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    try {
      await api.post("/auth/forgot-password", { email });
    } finally {
      setSubmitting(false);
      setSubmitted(true);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950">
      <div className="w-full max-w-sm bg-slate-900 border border-slate-800 rounded-lg p-6">
        <h1 className="text-xl font-bold text-emerald-400 mb-1">Reset your password</h1>
        <p className="text-slate-500 text-sm mb-6">
          Enter the email on your account and we'll send a reset link.
        </p>

        {submitted ? (
          <div className="bg-emerald-500/10 text-emerald-400 text-sm p-3 rounded">
            If an account exists for that email, a reset link has been sent. Check your inbox.
          </div>
        ) : (
          <form onSubmit={handleSubmit}>
            <label className="block text-sm text-slate-400 mb-1">Email</label>
            <input
              type="email"
              placeholder="you@example.com"
              className="w-full mb-4 px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
            <button
              disabled={submitting}
              className="w-full bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 rounded py-2 text-sm font-medium"
            >
              {submitting ? "Sending…" : "Send reset link"}
            </button>
          </form>
        )}

        <p className="text-sm text-slate-500 mt-4 text-center">
          <Link to="/login" className="text-emerald-400">Back to sign in</Link>
        </p>
      </div>
    </div>
  );
}
