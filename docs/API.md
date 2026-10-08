# CyberSentinel API Reference

Base URL: `http://localhost:4000/api`
Auth: `Authorization: Bearer <token>` (obtained from `/auth/login` or `/auth/register`)

## Authentication (public)
| Method | Path | Body |
|---|---|---|
| POST | `/auth/register` | `full_name, username, email, password, password_confirmation, role_name` |
| POST | `/auth/login` | `identifier, password` (identifier = email or username) |

## Authentication (any authenticated role)
| Method | Path | Notes |
|---|---|---|
| POST | `/auth/logout` | revokes the current token |
| GET | `/auth/me` | current user |
| POST | `/auth/password-reset` | `password, password_confirmation` |
| GET | `/dashboard/stats` | role-aware stats cards |

## Administrator (`/admin/*`)
| Method | Path |
|---|---|
| GET | `/admin/users` |
| GET | `/admin/users/:id` |
| PUT | `/admin/users/:id` |
| PUT | `/admin/users/:id/status` — `status: active\|disabled` |
| GET/POST/PUT/DELETE | `/admin/detection-rules[/:id]` |
| GET | `/admin/audit-logs` |

## Security Analyst (+ Administrator)
| Method | Path |
|---|---|
| GET | `/security-events`, `/security-events/:id` |
| GET | `/alerts`, `/alerts/:id` |
| PUT | `/alerts/:id` — `status` |
| POST | `/alerts/:id/acknowledge` |
| GET/POST/PUT | `/incidents[/:id]` — POST body: `{alert_id, title?, description?, severity?}` |
| GET/POST/PUT | `/investigations[/:id]` — POST body: `{incident_id}`; PUT body: `{conclusion}` |
| POST | `/investigations/:id/notes` — `{note}` |
| GET/POST | `/response-actions` — POST body: `{incident_id, action_type, description?}` |

### Simulation (safe, database-only — see backend README)
`POST /simulation/failed-login | port-scan | suspicious-ip | data-transfer | access-denied | unknown-device`

## Manager (`/manager/*`, read-only)
| Method | Path |
|---|---|
| GET | `/manager/incidents[/:id]` |
| GET | `/manager/alerts` |
| GET | `/manager/reports/summary` |
| GET | `/manager/reports/trends` |

## WebSocket (real-time alerts)
Connect to `ws://localhost:4000/socket` with `{token}` param, join topic `alerts:lobby`, listen for the `new_alert` event.
