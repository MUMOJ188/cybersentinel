defmodule CybersentinelWeb.AlertChannel do
  use CybersentinelWeb, :channel
  alias Cybersentinel.Alerts

  @impl true
  def join("alerts:lobby", _payload, socket) do
    Alerts.subscribe()
    {:ok, socket}
  end

  @impl true
  def handle_info({:new_alert, alert}, socket) do
    push(socket, "new_alert", %{
      id: alert.id,
      alert_type: alert.alert_type,
      severity: alert.severity,
      status: alert.status,
      description: alert.description,
      source_ip: alert.source_ip,
      inserted_at: alert.inserted_at
    })

    {:noreply, socket}
  end
end
