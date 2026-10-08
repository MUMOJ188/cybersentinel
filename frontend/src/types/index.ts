export type Role = "administrator" | "security_analyst" | "manager";

export interface User {
  id: string;
  full_name: string;
  username: string;
  email: string;
  role: Role;
  status: "active" | "disabled";
}

export interface Alert {
  id: string;
  alert_type: string;
  severity: "low" | "medium" | "high" | "critical";
  status: "new" | "acknowledged" | "investigating" | "resolved" | "false_positive";
  description: string;
  source_ip: string | null;
  inserted_at: string;
  security_event?: { id: string; event_type: string };
  detection_rule?: { id: string; name: string };
  user?: { id: string; username: string };
  device?: { id: string; device_name: string };
}

export interface Incident {
  id: string;
  incident_number: string;
  title: string;
  description: string | null;
  severity: "low" | "medium" | "high" | "critical";
  status: "new" | "investigating" | "contained" | "resolved";
  source_ip: string | null;
  resolution_notes: string | null;
  inserted_at: string;
  updated_at: string;
  assigned_analyst?: { username: string } | null;
  response_actions?: { id: string; action_type: string; description: string | null; inserted_at: string }[];
  investigations?: {
    id: string;
    started_at: string;
    completed_at: string | null;
    conclusion: string | null;
    notes: { id: string; note: string; inserted_at: string }[];
  }[];
}

export interface SecurityEvent {
  id: string;
  event_type: string;
  source_ip: string | null;
  destination_ip: string | null;
  target: string | null;
  description: string | null;
  metadata: Record<string, unknown>;
  occurred_at: string;
}
