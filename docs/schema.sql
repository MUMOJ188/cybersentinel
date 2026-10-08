-- CyberSentinel database schema
-- Generated to match backend/priv/repo/migrations/*.exs exactly.
--
-- You do NOT need to run this by hand if you use the app normally —
-- `mix ecto.setup` (or `mix ecto.migrate`) applies the migrations and
-- produces this same schema. This file exists as (a) a readable
-- reference for your report/diagram, and (b) something you can paste
-- directly into the Supabase SQL editor if you ever want to stand up
-- the schema without running mix.
--
-- If you DO run this by hand, tell Ecto not to re-run these migrations:
--   INSERT INTO schema_migrations (version) SELECT unnest(ARRAY[
--     20260924000001,20260924000002,20260924000003,20260924000004,
--     20260924000005,20260924000006,20260924000007,20260924000008,
--     20260924000009,20260924000010,20260924000011,20260924000012
--   ]);
-- (Ecto creates the schema_migrations table itself on first `mix ecto.migrate`.)

create extension if not exists pgcrypto; -- gives us gen_random_uuid()

-- ========================= roles =========================
create table roles (
  id uuid primary key default gen_random_uuid(),
  name varchar(255) not null,
  inserted_at timestamp not null default now(),
  updated_at timestamp not null default now(),
  constraint roles_name_check check (name in ('administrator','security_analyst','manager'))
);
create unique index roles_name_index on roles (name);

-- ========================= users =========================
create table users (
  id uuid primary key default gen_random_uuid(),
  full_name varchar(255) not null,
  username varchar(255) not null,
  email varchar(255) not null,
  password_hash varchar(255) not null,
  role_id uuid not null references roles(id) on delete restrict,
  status varchar(255) not null default 'active'
    constraint users_status_check check (status in ('active','disabled')),
  inserted_at timestamp not null default now(),
  updated_at timestamp not null default now()
);
create unique index users_email_index on users (email);
create unique index users_username_index on users (username);
create index users_role_id_index on users (role_id);
create index users_status_index on users (status);

-- ========================= devices =========================
create table devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  device_identifier varchar(255) not null,
  device_name varchar(255),
  device_type varchar(255),
  is_known boolean not null default true,
  last_seen_at timestamp,
  inserted_at timestamp not null default now(),
  updated_at timestamp not null default now()
);
create index devices_user_id_index on devices (user_id);
create unique index devices_user_id_device_identifier_index on devices (user_id, device_identifier);

-- ========================= detection_rules =========================
create table detection_rules (
  id uuid primary key default gen_random_uuid(),
  name varchar(255) not null,
  event_type varchar(255) not null
    constraint detection_rules_event_type_check check (event_type in (
      'failed_login','port_scan','suspicious_ip','large_data_transfer',
      'access_denied','unknown_device_login'
    )),
  threshold integer not null,
  time_window_seconds integer not null,
  severity varchar(255) not null
    constraint detection_rules_severity_check check (severity in ('low','medium','high','critical')),
  description text,
  enabled boolean not null default true,
  created_by uuid references users(id) on delete set null,
  inserted_at timestamp not null default now(),
  updated_at timestamp not null default now()
);
create index detection_rules_event_type_index on detection_rules (event_type);
create index detection_rules_enabled_index on detection_rules (enabled);

-- ========================= security_events =========================
create table security_events (
  id uuid primary key default gen_random_uuid(),
  event_type varchar(255) not null
    constraint security_events_event_type_check check (event_type in (
      'failed_login','port_scan','suspicious_ip','large_data_transfer',
      'access_denied','unknown_device_login'
    )),
  user_id uuid references users(id) on delete set null,
  source_ip varchar(255),
  destination_ip varchar(255),
  device_id uuid references devices(id) on delete set null,
  target varchar(255),
  description text,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamp not null,
  inserted_at timestamp not null default now()
);
create index security_events_event_type_index on security_events (event_type);
create index security_events_source_ip_index on security_events (source_ip);
create index security_events_user_id_index on security_events (user_id);
create index security_events_occurred_at_index on security_events (occurred_at);
create index security_events_event_type_source_ip_occurred_at_index
  on security_events (event_type, source_ip, occurred_at);

-- ========================= ip_blocklist =========================
create table ip_blocklist (
  id uuid primary key default gen_random_uuid(),
  ip_address varchar(255) not null,
  description text,
  enabled boolean not null default true,
  inserted_at timestamp not null default now(),
  updated_at timestamp not null default now()
);
create unique index ip_blocklist_ip_address_index on ip_blocklist (ip_address);

-- ========================= alerts =========================
create table alerts (
  id uuid primary key default gen_random_uuid(),
  alert_type varchar(255) not null,
  severity varchar(255) not null
    constraint alerts_severity_check check (severity in ('low','medium','high','critical')),
  security_event_id uuid not null references security_events(id) on delete cascade,
  detection_rule_id uuid references detection_rules(id) on delete set null,
  source_ip varchar(255),
  user_id uuid references users(id) on delete set null,
  device_id uuid references devices(id) on delete set null,
  description text,
  status varchar(255) not null default 'new'
    constraint alerts_status_check check (status in (
      'new','acknowledged','investigating','resolved','false_positive'
    )),
  inserted_at timestamp not null default now(),
  updated_at timestamp not null default now()
);
create index alerts_status_index on alerts (status);
create index alerts_severity_index on alerts (severity);
create index alerts_security_event_id_index on alerts (security_event_id);
create index alerts_detection_rule_id_index on alerts (detection_rule_id);

-- ========================= incidents =========================
create table incidents (
  id uuid primary key default gen_random_uuid(),
  incident_number varchar(255) not null,
  title varchar(255) not null,
  description text,
  severity varchar(255) not null
    constraint incidents_severity_check check (severity in ('low','medium','high','critical')),
  alert_id uuid references alerts(id) on delete set null,
  source_ip varchar(255),
  affected_user_id uuid references users(id) on delete set null,
  affected_device_id uuid references devices(id) on delete set null,
  assigned_analyst_id uuid references users(id) on delete set null,
  status varchar(255) not null default 'new'
    constraint incidents_status_check check (status in ('new','investigating','contained','resolved')),
  resolution_notes text,
  inserted_at timestamp not null default now(),
  updated_at timestamp not null default now()
);
create unique index incidents_incident_number_index on incidents (incident_number);
create index incidents_status_index on incidents (status);
create index incidents_assigned_analyst_id_index on incidents (assigned_analyst_id);
create index incidents_alert_id_index on incidents (alert_id);

-- ========================= investigations =========================
create table investigations (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references incidents(id) on delete cascade,
  analyst_id uuid not null references users(id) on delete set null,
  started_at timestamp not null,
  completed_at timestamp,
  conclusion text,
  inserted_at timestamp not null default now(),
  updated_at timestamp not null default now()
);
create index investigations_incident_id_index on investigations (incident_id);
create index investigations_analyst_id_index on investigations (analyst_id);

-- ========================= investigation_notes =========================
create table investigation_notes (
  id uuid primary key default gen_random_uuid(),
  investigation_id uuid not null references investigations(id) on delete cascade,
  analyst_id uuid not null references users(id) on delete set null,
  note text not null,
  inserted_at timestamp not null default now()
);
create index investigation_notes_investigation_id_index on investigation_notes (investigation_id);

-- ========================= response_actions =========================
create table response_actions (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references incidents(id) on delete cascade,
  analyst_id uuid not null references users(id) on delete set null,
  action_type varchar(255) not null
    constraint response_actions_action_type_check check (action_type in (
      'account_locked','password_reset_requested','ip_blocked',
      'device_isolated','access_revoked','investigation_completed'
    )),
  description text,
  inserted_at timestamp not null default now()
);
create index response_actions_incident_id_index on response_actions (incident_id);

-- ========================= audit_logs =========================
create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete set null,
  action varchar(255) not null,
  resource_type varchar(255),
  resource_id uuid,
  description text,
  ip_address varchar(255),
  inserted_at timestamp not null default now()
);
create index audit_logs_user_id_index on audit_logs (user_id);
create index audit_logs_action_index on audit_logs (action);
create index audit_logs_resource_type_resource_id_index on audit_logs (resource_type, resource_id);

-- ========================= seed data =========================
insert into roles (name) values ('administrator'), ('security_analyst'), ('manager');

insert into detection_rules (name, event_type, threshold, time_window_seconds, severity, description) values
  ('Brute Force Login Detection', 'failed_login', 5, 300, 'high',
   '5+ failed logins from the same source IP within 5 minutes.'),
  ('Port Scan Detection', 'port_scan', 10, 60, 'medium',
   '10+ distinct destination ports probed from the same source IP within 1 minute.'),
  ('Large Data Transfer Detection', 'large_data_transfer', 500000000, 0, 'medium',
   'Single transfer exceeding 500MB.'),
  ('Repeated Access Denied Detection', 'access_denied', 5, 600, 'medium',
   '5+ access-denied events for the same user within 10 minutes.'),
  ('Unknown Device Login Detection', 'unknown_device_login', 1, 0, 'medium',
   'Login from a device not previously associated with the user.');

-- Note: rule 3 ("Suspicious IP") is NOT a row here — it's evaluated
-- against the ip_blocklist table on every event, not threshold-based.
-- See backend/lib/cybersentinel/detection_engine.ex, check_blocklist/1.
