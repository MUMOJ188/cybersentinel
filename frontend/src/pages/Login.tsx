import { FormEvent, useState } from "react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import { LockKeyhole, UserRound } from "lucide-react";
import { useAuth } from "../context/AuthContext";
import { homeFor } from "../routes/ProtectedRoute";

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const successMessage = (location.state as { successMessage?: string } | null)?.successMessage ?? null;
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      const user = await login(email, password);
      navigate(homeFor(user.role));
    } catch (err: any) {
      setError(err.response?.data?.error ?? "Login failed");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="login-page">
      <div className="login-scene" aria-hidden="true">
        <div className="login-pixel-field login-pixel-field-left" />
        <div className="login-pixel-field login-pixel-field-right" />
        <div className="login-trace login-trace-top-left" />
        <div className="login-trace login-trace-top-right" />
        <div className="login-trace login-trace-bottom-left" />
        <div className="login-trace login-trace-bottom-right" />
        <div className="login-node login-node-top-left" />
        <div className="login-node login-node-top-right" />
        <div className="login-node login-node-bottom-left" />
        <div className="login-node login-node-bottom-right" />
      </div>

      <form onSubmit={handleSubmit} className="login-card">
        <div className="login-card-inner">
          <div className="login-chevron" aria-hidden="true"><span /><span /></div>
          <p className="login-brand">CYBERSENTINEL</p>
          <h1 className="login-title">LOGIN</h1>
          <div className="login-chevron login-chevron-bottom" aria-hidden="true"><span /><span /></div>

        {successMessage && (
          <div className="login-notice login-notice-success" role="status">{successMessage}</div>
        )}
        {error && <div className="login-notice login-notice-error" role="alert">{error}</div>}

          <label className="sr-only" htmlFor="login-email">Email</label>
          <div className="login-field">
            <UserRound className="login-field-icon" size={16} strokeWidth={2} aria-hidden="true" />
            <input
              id="login-email"
              type="email"
              autoComplete="username"
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          <label className="sr-only" htmlFor="login-password">Password</label>
          <div className="login-field">
            <LockKeyhole className="login-field-icon" size={16} strokeWidth={2} aria-hidden="true" />
            <input
              id="login-password"
              type="password"
              autoComplete="current-password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          <div className="login-links-row">
            <Link to="/forgot-password">Forgot password?</Link>
          </div>

          <button type="submit" disabled={submitting} className="login-submit">
            {submitting ? "Signing in…" : "Sign in"}
          </button>

          <p className="login-register">
            No account? <Link to="/register">Register</Link>
          </p>
        </div>
      </form>
    </main>
  );
}