defmodule CybersentinelWeb.Manager.AlertController do
  use CybersentinelWeb, :controller
  alias Cybersentinel.Alerts

  def index(conn, params) do
    alerts = Alerts.list_alerts(params)

    json(conn, %{
      alerts:
        Enum.map(alerts, fn a ->
          %{
            id: a.id,
            alert_type: a.alert_type,
            severity: a.severity,
            status: a.status,
            source_ip: a.source_ip,
            inserted_at: a.inserted_at
          }
        end)
    })
  end
end
