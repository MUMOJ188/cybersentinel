defmodule CybersentinelWeb.AlertController do
  use CybersentinelWeb, :controller
  alias Cybersentinel.Alerts

  def index(conn, params) do
    alerts = Alerts.list_alerts(params)
    json(conn, %{alerts: Enum.map(alerts, &alert_json/1)})
  end

  def show(conn, %{"id" => id}) do
    alert = Alerts.get_alert!(id)
    json(conn, %{alert: alert_json(alert)})
  end

  def update(conn, %{"id" => id, "status" => status}) do
    alert = Alerts.get_alert!(id)

    case Alerts.update_status(alert, status) do
      {:ok, updated} -> json(conn, %{alert: alert_json(updated)})
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: errors(changeset)})
    end
  end

  def acknowledge(conn, %{"id" => id}) do
    alert = Alerts.get_alert!(id)

    case Alerts.acknowledge(alert) do
      {:ok, updated} -> json(conn, %{alert: alert_json(updated)})
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: errors(changeset)})
    end
  end

  defp alert_json(a) do
    %{
      id: a.id,
      alert_type: a.alert_type,
      severity: a.severity,
      status: a.status,
      description: a.description,
      source_ip: a.source_ip,
      inserted_at: a.inserted_at,
      security_event: a.security_event && %{id: a.security_event.id, event_type: a.security_event.event_type},
      detection_rule: a.detection_rule && %{id: a.detection_rule.id, name: a.detection_rule.name},
      user: a.user && %{id: a.user.id, username: a.user.username},
      device: a.device && %{id: a.device.id, device_name: a.device.device_name}
    }
  end

  defp errors(changeset), do: Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
end
