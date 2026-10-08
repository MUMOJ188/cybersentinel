defmodule Cybersentinel.DetectionEngineTest do
  use Cybersentinel.DataCase, async: true
  import Cybersentinel.Fixtures

  alias Cybersentinel.{SecurityEvents, DetectionRules, DetectionEngine, Alerts, IpBlocklist}

  defp event_attrs(overrides) do
    Map.merge(
      %{"event_type" => "failed_login", "source_ip" => "192.168.1.20", "occurred_at" => DateTime.utc_now()},
      overrides
    )
  end

  test "brute force: 5 failed logins from the same IP within the window creates one alert" do
    DetectionRules.create_rule(%{
      name: "Brute Force",
      event_type: "failed_login",
      threshold: 5,
      time_window_seconds: 300,
      severity: "high"
    })

    alerts =
      for _ <- 1..5 do
        {:ok, event} = SecurityEvents.create_event(event_attrs(%{}))
        DetectionEngine.evaluate(event)
      end
      |> List.flatten()

    assert length(alerts) == 1
    assert hd(alerts).alert_type == "possible_brute_force"
    assert hd(alerts).severity == "high"

    # A 6th event within the same window should NOT create a second alert
    {:ok, event6} = SecurityEvents.create_event(event_attrs(%{}))
    assert DetectionEngine.evaluate(event6) == []

    assert length(Alerts.list_alerts()) == 1
  end

  test "port scan: many distinct ports from one IP triggers an alert" do
    DetectionRules.create_rule(%{
      name: "Port Scan",
      event_type: "port_scan",
      threshold: 3,
      time_window_seconds: 60,
      severity: "medium"
    })

    alerts =
      for port <- ["22", "80", "443"] do
        {:ok, event} = SecurityEvents.create_event(event_attrs(%{"event_type" => "port_scan", "target" => port}))
        DetectionEngine.evaluate(event)
      end
      |> List.flatten()

    assert Enum.any?(alerts, &(&1.alert_type == "possible_port_scan"))
  end

  test "suspicious IP: an event from a blocklisted IP always alerts" do
    {:ok, _} = IpBlocklist.add(%{"ip_address" => "203.0.113.42"})

    {:ok, event} =
      SecurityEvents.create_event(event_attrs(%{"event_type" => "suspicious_ip", "source_ip" => "203.0.113.42"}))

    alerts = DetectionEngine.evaluate(event)
    assert Enum.any?(alerts, &(&1.alert_type == "suspicious_ip"))
  end

  test "large data transfer: single event over the byte threshold alerts" do
    DetectionRules.create_rule(%{
      name: "Large Transfer",
      event_type: "large_data_transfer",
      threshold: 500_000_000,
      time_window_seconds: 0,
      severity: "medium"
    })

    {:ok, event} =
      SecurityEvents.create_event(
        event_attrs(%{"event_type" => "large_data_transfer", "metadata" => %{"bytes_transferred" => 750_000_000}})
      )

    alerts = DetectionEngine.evaluate(event)
    assert Enum.any?(alerts, &(&1.alert_type == "unusual_data_transfer"))
  end

  test "repeated access denied: 5 denials for the same user within the window alerts" do
    user = user_fixture("security_analyst")

    DetectionRules.create_rule(%{
      name: "Repeated Access Denied",
      event_type: "access_denied",
      threshold: 5,
      time_window_seconds: 600,
      severity: "medium"
    })

    alerts =
      for _ <- 1..5 do
        {:ok, event} =
          SecurityEvents.create_event(event_attrs(%{"event_type" => "access_denied", "user_id" => user.id}))

        DetectionEngine.evaluate(event)
      end
      |> List.flatten()

    assert Enum.any?(alerts, &(&1.alert_type == "repeated_unauthorized_access"))
  end

  test "unknown device login: metadata known_device=false alerts" do
    DetectionRules.create_rule(%{
      name: "Unknown Device",
      event_type: "unknown_device_login",
      threshold: 1,
      time_window_seconds: 0,
      severity: "medium"
    })

    {:ok, event} =
      SecurityEvents.create_event(
        event_attrs(%{"event_type" => "unknown_device_login", "metadata" => %{"known_device" => false}})
      )

    alerts = DetectionEngine.evaluate(event)
    assert Enum.any?(alerts, &(&1.alert_type == "suspicious_login_device"))
  end
end
