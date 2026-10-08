defmodule Cybersentinel.IncidentsTest do
  use Cybersentinel.DataCase, async: true
  import Cybersentinel.Fixtures

  alias Cybersentinel.{SecurityEvents, Alerts, Incidents}

  test "creating an incident from an alert moves the alert to investigating" do
    analyst = user_fixture("security_analyst")

    {:ok, event} =
      SecurityEvents.create_event(%{
        "event_type" => "failed_login",
        "source_ip" => "192.168.1.20",
        "occurred_at" => DateTime.utc_now()
      })

    {:ok, alert} =
      Alerts.create_alert(%{
        alert_type: "possible_brute_force",
        severity: "high",
        security_event_id: event.id,
        source_ip: event.source_ip,
        status: "new"
      })

    {:ok, incident} = Incidents.create_incident_from_alert(alert.id, %{}, analyst)

    assert incident.incident_number == "INC-0001"
    assert incident.status == "new"
    assert incident.assigned_analyst_id == analyst.id

    reloaded_alert = Alerts.get_alert!(alert.id)
    assert reloaded_alert.status == "investigating"
  end

  test "an incident can be driven through the full status workflow to resolved" do
    analyst = user_fixture("security_analyst")

    {:ok, event} =
      SecurityEvents.create_event(%{
        "event_type" => "failed_login",
        "source_ip" => "192.168.1.20",
        "occurred_at" => DateTime.utc_now()
      })

    {:ok, alert} =
      Alerts.create_alert(%{
        alert_type: "possible_brute_force",
        severity: "high",
        security_event_id: event.id,
        source_ip: event.source_ip,
        status: "new"
      })

    {:ok, incident} = Incidents.create_incident_from_alert(alert.id, %{}, analyst)

    {:ok, incident} = Incidents.transition_status(incident, "investigating")
    assert incident.status == "investigating"

    {:ok, incident} = Incidents.transition_status(incident, "contained")
    assert incident.status == "contained"

    {:ok, incident} = Incidents.update_incident(incident, %{"status" => "resolved", "resolution_notes" => "Account locked, password reset."})
    assert incident.status == "resolved"
    assert incident.resolution_notes =~ "locked"
  end
end
