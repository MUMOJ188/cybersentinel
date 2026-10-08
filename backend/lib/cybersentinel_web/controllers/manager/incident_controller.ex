defmodule CybersentinelWeb.Manager.IncidentController do
  use CybersentinelWeb, :controller
  alias Cybersentinel.Incidents

  def index(conn, params) do
    json(conn, %{incidents: Enum.map(Incidents.list_incidents(params), &incident_json/1)})
  end

  def show(conn, %{"id" => id}) do
    json(conn, %{incident: incident_json(Incidents.get_incident!(id), detailed: true)})
  end

  defp incident_json(i, opts \\ []) do
    base = %{
      id: i.id,
      incident_number: i.incident_number,
      title: i.title,
      severity: i.severity,
      status: i.status,
      source_ip: i.source_ip,
      inserted_at: i.inserted_at,
      updated_at: i.updated_at,
      assigned_analyst: i.assigned_analyst && %{username: i.assigned_analyst.username}
    }

    if opts[:detailed] do
      Map.merge(base, %{
        description: i.description,
        resolution_notes: i.resolution_notes,
        response_actions: Enum.map(i.response_actions, &%{action_type: &1.action_type, description: &1.description, inserted_at: &1.inserted_at})
      })
    else
      base
    end
  end
end
