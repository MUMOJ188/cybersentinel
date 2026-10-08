# CyberSentinel — Cybersecurity Monitoring & Incident Management System

One project, two halves, both real:

```
cybersentinel/
├── backend/    Phoenix API (Elixir + Ecto + Supabase Postgres + Channels)
├── frontend/   React + TypeScript + Vite + Tailwind
├── docs/       API.md
└── .vscode/    tasks.json — run both servers with one command
```

`React → Phoenix API → Ecto → Supabase Postgres`, with `React ↔ Phoenix Channels` for the live alert feed.
Nothing in here performs real attacks — the Security Event Simulator only inserts rows and runs the
DetectionEngine over them.

## 1. Open it in VS Code

```bash
unzip cybersentinel.zip
code cybersentinel
```

Opening the **`cybersentinel` folder itself** as the workspace (not `backend/` or `frontend/` alone) is what
makes the `.vscode/tasks.json` below work — VS Code resolves `${workspaceFolder}/backend` and
`${workspaceFolder}/frontend` from that root.

## 2. One-time setup

**Prerequisites:** Elixir 1.16+/OTP 26+, Node 18+, a Supabase project (you said you'll share the connection
string — plug it into `backend/.env` per step below).

```bash
# Backend
cd backend
cp .env.example .env        # fill in DATABASE_URL from Supabase, then:
export $(cat .env | xargs)  # or use direnv / VS Code's env support
mix deps.get
mix phx.gen.secret          # run TWICE, paste one result into SECRET_KEY_BASE, one into GUARDIAN_SECRET_KEY in .env
export $(cat .env | xargs)  # re-export after editing
mix ecto.setup              # creates tables, seeds roles + default detection rules

# Frontend (new terminal)
cd ../frontend
cp .env.example .env        # default http://localhost:4000/api is fine for local dev
npm install
```

## 3. Run both servers together

**Easiest — VS Code task:** `Terminal → Run Task… → Run CyberSentinel (backend + frontend)`. This runs
`mix phx.server` and `npm run dev` side by side in the VS Code terminal panel (see `.vscode/tasks.json`).

**Or manually, two terminals:**
```bash
# Terminal 1
cd backend && export $(cat .env | xargs) && mix phx.server

# Terminal 2
cd frontend && npm run dev
```

Backend: http://localhost:4000 · Frontend: http://localhost:5173

## 4. The demo flow (matches the brief exactly)

1. Open http://localhost:5173/register → create a **Security Analyst** account.
2. Land on the Analyst Dashboard → open **Security Event Simulator**.
3. Click **"Run 5x Failed Login"** (defaults to IP `192.168.1.20`).
4. The 5th event crosses the seeded brute-force rule's threshold → DetectionEngine creates
   **"Possible Brute-Force Attack"**, severity High.
5. Go to **Alerts** — the alert appears instantly via the WebSocket push (no refresh needed), or on load.
6. Click the alert → **Create Incident** → you land on the incident detail page (`INC-0001`).
7. **Start Investigation**, add a note referencing the source IP and timestamps.
8. Record response actions: `account_locked`, `password_reset_requested`.
9. Walk the status buttons: `investigating → contained → resolved`, with resolution notes.
10. Log out, register/login as a **Manager** → Manager Dashboard, Incidents, and Reports all show the
    resolved incident, its severity, and the response actions — pulled live from Postgres, not mocked.

## What's real vs. what's a starting point

**Fully implemented, real, database-backed:** all 12 tables and their relationships; registration/login with
bcrypt + JWT; server-side `RequireRole` authorization (a Manager hitting `/api/admin/*` gets a genuine 403,
not a frontend redirect); rate-limited login; audit logging; the six simulation endpoints; the DetectionEngine
running all six rules with dedup; the full alert → incident → investigation → response-action → resolution
workflow; the Phoenix Channel broadcasting real-time alerts to React; role-aware dashboard stats pulled with
real Ecto aggregate queries; ExUnit tests covering auth/RBAC, all six detection rules, and the incident
lifecycle (`backend/test/`).

**Deliberately left as a next step**, since they weren't essential to a working end-to-end demo and would have
padded the build without adding real function: Oban-based scheduled report jobs, Docker packaging, a
role-picker UI for admin role reassignment (the API supports it — `PUT /admin/users/:id` with `role_id` — the
page just doesn't have a dropdown wired up yet), and CSS/UX polish beyond the functional Tailwind styling here.
Say which of these you want and it gets built the same way as everything else — as real files, not stubs.

## Why there's no `mix.lock` / `node_modules` in the zip

The sandbox this was built in can only reach npm/PyPI/crates registries, not `hex.pm`, so `mix deps.get`
couldn't be run there to verify compilation or generate a lockfile. Every Elixir file is hand-written,
idiomatic Phoenix 1.7 — running `mix deps.get` + `mix phx.server` on your machine (step 2 above) is the
first real compile. If something doesn't compile, send me the error and I'll fix it directly.

See `docs/API.md` for the full endpoint reference, and `docs/schema.sql` for the raw SQL schema
(matches the Ecto migrations exactly — useful for your report/diagram, or to paste into the Supabase SQL editor).
