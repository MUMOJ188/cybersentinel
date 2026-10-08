defmodule CybersentinelWeb.Simulation.SimulationController do
  use CybersentinelWeb, :controller

  alias Cybersentinel.{SecurityEvents, DetectionEngine, AuditLogs}
  alias Cybersentinel.Guardian

  @moduledoc """
  Safe security-event simulator. Every action here only inserts a row into
  `security_events` (optionally a `devices` row) and then runs the
  DetectionEngine over it. NONE of these perform real network requests,
  port probes, logins, or transfers against any system.
  """

  def failed_login(conn, params) do
    ingest(conn, %{
      "event_type" => "failed_login",
      "source_ip" => params["source_ip"] || "192.168.1.20",
      "target" => params["username"] || "admin",
      "description" => "Simulated failed login attempt for '#{params["username"] || "admin"}'",
      "metadata" => %{"username" => params["username"] || "admin"}
    })
  end

  def port_scan(conn, params) do
    port = params["port"] || Integer.to_string(Enum.random(1..65535))

    ingest(conn, %{
      "event_type" => "port_scan",
      "source_ip" => params["source_ip"] || "10.0.0.66",
      "target" => port,
      "description" => "Simulated probe of port #{port}"
    })
  end

  def suspicious_ip(conn, params) do
    ip = params["source_ip"] || "203.0.113.42"

    ingest(conn, %{
      "event_type" => "suspicious_ip",
      "source_ip" => ip,
      "description" => "Simulated event flagged from blocklisted-candidate IP #{ip}"
    })
  end

  def data_transfer(conn, params) do
    bytes = params["bytes_transferred"] || 750_000_000

    ingest(conn, %{
      "event_type" => "large_data_transfer",
      "source_ip" => params["source_ip"] || "192.168.1.55",
      "destination_ip" => params["destination_ip"] || "198.51.100.10",
      "description" => "Simulated transfer of #{bytes} bytes",
      "metadata" => %{"bytes_transferred" => bytes}
    })
  end

  def access_denied(conn, params) do
    user = Guardian.Plug.current_resource(conn)

    ingest(conn, %{
      "event_type" => "access_denied",
      "user_id" => params["user_id"] || user.id,
      "source_ip" => params["source_ip"] || "192.168.1.77",
      "target" => params["resource"] || "/admin/settings",
      "description" => "Simulated access-denied event for #{params["resource"] || "/admin/settings"}"
    })
  end

  def unknown_device(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    target_user_id = params["user_id"] || user.id
    device_identifier = params["device_identifier"] || "sim-device-#{System.unique_integer([:positive])}"

    {status, device} = SecurityEvents.register_or_check_device(target_user_id, device_identifier, %{
      "device_name" => params["device_name"] || "Unrecognized Laptop",
      "device_type" => "laptop"
    })

    ingest(conn, %{
      "event_type" => "unknown_device_login",
      "user_id" => target_user_id,
      "device_id" => device && device.id,
      "source_ip" => params["source_ip"] || "192.168.1.90",
      "description" => "Simulated login from device #{device_identifier}",
      "metadata" => %{"known_device" => status == :known, "device_identifier" => device_identifier}
    })
  end

  ## Shared: insert event, run detection engine, respond with what fired

  defp ingest(conn, attrs) do
    attrs = Map.put_new(attrs, "occurred_at", DateTime.utc_now() |> DateTime.truncate(:second))

    case SecurityEvents.create_event(attrs) do
      {:ok, event} ->
        fired_alerts = DetectionEngine.evaluate(event)

        AuditLogs.log(%{
          user_id: current_user_id(conn),
          action: "simulation_event_generated",
          resource_type: "security_event",
          resource_id: event.id,
          description: "Simulated #{event.event_type} event (#{length(fired_alerts)} alert(s) triggered)",
          ip_address: client_ip(conn)
        })

        conn
        |> put_status(:created)
        |> json(%{
          event: event_json(event),
          alerts_triggered: Enum.map(fired_alerts, &alert_json/1)
        })

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  defp current_user_id(conn) do
    case Guardian.Plug.current_resource(conn) do
      nil -> nil
      user -> user.id
    end
  end

  defp client_ip(conn), do: conn.remote_ip |> :inet.ntoa() |> to_string()

  defp event_json(event) do
    %{
      id: event.id,
      event_type: event.event_type,
      source_ip: event.source_ip,
      destination_ip: event.destination_ip,
      target: event.target,
      description: event.description,
      metadata: event.metadata,
      occurred_at: event.occurred_at
    }
  end

  defp alert_json(%Cybersentinel.Alerts.Alert{} = alert) do
    %{
      id: alert.id,
      alert_type: alert.alert_type,
      severity: alert.severity,
      description: alert.description,
      status: alert.status,
      source_ip: alert.source_ip
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
