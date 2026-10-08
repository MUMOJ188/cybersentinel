import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import type { Role } from "../types";

export default function Register() {
  const { register } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({
    full_name: "",
    username: "",
    email: "",
    password: "",
    password_confirmation: "",
    role_name: "security_analyst" as Role
  });
  const [errors, setErrors] = useState<Record<string, string[]> | null>(null);
  const [submitting, setSubmitting] = useState(false);

  function set<K extends keyof typeof form>(key: K, value: (typeof form)[K]) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setErrors(null);
    setSubmitting(true);
    try {
      await register(form);
      navigate("/login", {
        state: { successMessage: "Registration successful. Please log in with your email and password." }
      });
    } catch (err: any) {
      setErrors(err.response?.data?.errors ?? { base: ["Registration failed"] });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950 py-10">
      <form onSubmit={handleSubmit} className="w-full max-w-sm bg-slate-900 border border-slate-800 rounded-lg p-6">
        <h1 className="text-xl font-bold text-emerald-400 mb-6">Create an account</h1>

        {errors && (
          <div className="bg-red-500/10 text-red-400 text-xs p-2 rounded mb-4 space-y-1">
            {Object.entries(errors).map(([field, msgs]) => (
              <div key={field}>
                <strong>{field}:</strong> {msgs.join(", ")}
              </div>
            ))}
          </div>
        )}

        <Field label="Full Name" value={form.full_name} onChange={(v) => set("full_name", v)} />
        <Field label="Username" value={form.username} onChange={(v) => set("username", v)} />
        <Field label="Email" type="email" value={form.email} onChange={(v) => set("email", v)} />
        <Field label="Password" type="password" value={form.password} onChange={(v) => set("password", v)} />
        <Field
          label="Confirm Password"
          type="password"
          value={form.password_confirmation}
          onChange={(v) => set("password_confirmation", v)}
        />

        <label className="block text-sm text-slate-400 mb-1">Role</label>
        <select
          className="w-full mb-6 px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
          value={form.role_name}
          onChange={(e) => set("role_name", e.target.value as Role)}
        >
          <option value="administrator">Administrator</option>
          <option value="security_analyst">Security Analyst</option>
          <option value="manager">Manager</option>
        </select>

        <button
          disabled={submitting}
          className="w-full bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 rounded py-2 text-sm font-medium"
        >
          {submitting ? "Creating…" : "Register"}
        </button>

        <p className="text-sm text-slate-500 mt-4 text-center">
          Already have an account? <Link to="/login" className="text-emerald-400">Sign in</Link>
        </p>
      </form>
    </div>
  );
}

function Field({
  label,
  value,
  onChange,
  type = "text"
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
}) {
  return (
    <div className="mb-4">
      <label className="block text-sm text-slate-400 mb-1">{label}</label>
      <input
        type={type}
        className="w-full px-3 py-2 rounded bg-slate-800 border border-slate-700 text-sm"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        required
      />
    </div>
  );
}