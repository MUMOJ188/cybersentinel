alias Cybersentinel.Repo
alias Cybersentinel.Accounts.Role

for name <- Role.valid_roles() do
  Repo.insert!(%Role{name: name}, on_conflict: :nothing, conflict_target: :name)
end

IO.puts("Seeded roles: #{Enum.join(Role.valid_roles(), ", ")}")

alias Cybersentinel.DetectionRules

default_rules = [
  %{
    name: "Brute Force Login Detection",
    event_type: "failed_login",
    threshold: 5,
    time_window_seconds: 300,
    severity: "high",
    description: "5+ failed logins from the same source IP within 5 minutes."
  },
  %{
    name: "Port Scan Detection",
    event_type: "port_scan",
    threshold: 10,
    time_window_seconds: 60,
    severity: "medium",
    description: "10+ distinct destination ports probed from the same source IP within 1 minute."
  },
  %{
    name: "Large Data Transfer Detection",
    event_type: "large_data_transfer",
    threshold: 500_000_000,
    time_window_seconds: 0,
    severity: "medium",
    description: "Single transfer exceeding 500MB."
  },
  %{
    name: "Repeated Access Denied Detection",
    event_type: "access_denied",
    threshold: 5,
    time_window_seconds: 600,
    severity: "medium",
    description: "5+ access-denied events for the same user within 10 minutes."
  },
  %{
    name: "Unknown Device Login Detection",
    event_type: "unknown_device_login",
    threshold: 1,
    time_window_seconds: 0,
    severity: "medium",
    description: "Login from a device not previously associated with the user."
  }
]

for attrs <- default_rules do
  unless Repo.get_by(DetectionRules.DetectionRule, name: attrs.name) do
    DetectionRules.create_rule(attrs)
  end
end

IO.puts("Seeded #{length(default_rules)} default detection rules")
