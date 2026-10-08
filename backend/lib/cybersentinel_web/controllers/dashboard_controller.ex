defmodule CybersentinelWeb.DashboardController do
  use CybersentinelWeb, :controller

  import Ecto.Query
  alias Cybersentinel.{Accounts, Alerts, Incidents, DetectionRules, Repo, Guardian}
  alias Cybersentinel.SecurityEvents.SecurityEvent
  alias Cybersentinel.Alerts.Alert
  alias Cybersentinel.Accounts.User

  def stats(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    payload =
      case Accounts.role_name(user) do
        "administrator" -> admin_stats()
        "security_analyst" -> analyst_stats()
        "manager" -> manager_stats()
      end

    json(conn, payload)
  end

  defp admin_stats do
    %{
      total_users: Repo.aggregate(User, :count),
      active_users: Repo.aggregate(from(u in User, where: u.status == "active"), :count),
      security_analysts: role_count("security_analyst"),
      managers: role_count("manager"),
      active_detection_rules: DetectionRules.count_active(),
      total_alerts: Repo.aggregate(Alert, :count),
      active_incidents: incidents_open_count()
    }
  end

  defp analyst_stats do
    severities = Alerts.counts_by_severity()
    statuses = Incidents.counts_by_status()
    today_start = Date.utc_today() |> DateTime.new!(~T[00:00:00], "Etc/UTC")

    %{
      critical_alerts: Map.get(severities, "critical", 0),
      high_alerts: Map.get(severities, "high", 0),
      medium_alerts: Map.get(severities, "medium", 0),
      low_alerts: Map.get(severities, "low", 0),
      open_incidents: Map.get(statuses, "new", 0),
      investigating_incidents: Map.get(statuses, "investigating", 0),
      resolved_incidents: Map.get(statuses, "resolved", 0),
      events_today: Repo.aggregate(from(e in SecurityEvent, where: e.occurred_at >= ^today_start), :count)
    }
  end

  defp manager_stats do
    severities = Incidents.counts_by_severity()
    statuses = Incidents.counts_by_status()
    avg = Incidents.average_resolution_seconds()

    %{
      total_security_events: Repo.aggregate(SecurityEvent, :count),
      total_alerts: Repo.aggregate(Alert, :count),
      active_incidents: (statuses["new"] || 0) + (statuses["investigating"] || 0) + (statuses["contained"] || 0),
      resolved_incidents: Map.get(statuses, "resolved", 0),
      critical_incidents: Map.get(severities, "critical", 0),
      high_incidents: Map.get(severities, "high", 0),
      average_response_time_seconds: avg && round(avg)
    }
  end

  defp role_count(role_name) do
    from(u in User, join: r in assoc(u, :role), where: r.name == ^role_name)
    |> Repo.aggregate(:count)
  end

  defp incidents_open_count do
    from(i in Cybersentinel.Incidents.Incident, where: i.status != "resolved")
    |> Repo.aggregate(:count)
  end
end
