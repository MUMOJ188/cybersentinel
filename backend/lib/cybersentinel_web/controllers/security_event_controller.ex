defmodule CybersentinelWeb.SecurityEventController do
  use CybersentinelWeb, :controller
  alias Cybersentinel.SecurityEvents

  def index(conn, params) do
    events = SecurityEvents.list_events(params)
    json(conn, %{events: Enum.map(events, &event_json/1)})
  end

  def show(conn, %{"id" => id}) do
    event = SecurityEvents.get_event!(id)
    json(conn, %{event: event_json(event)})
  end

  defp event_json(e) do
    %{
      id: e.id,
      event_type: e.event_type,
      source_ip: e.source_ip,
      destination_ip: e.destination_ip,
      target: e.target,
      description: e.description,
      metadata: e.metadata,
      occurred_at: e.occurred_at,
      user: e.user && %{id: e.user.id, username: e.user.username},
      device: e.device && %{id: e.device.id, device_name: e.device.device_name, is_known: e.device.is_known}
    }
  end
end
