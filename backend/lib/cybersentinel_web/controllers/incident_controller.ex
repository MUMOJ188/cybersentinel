defmodule CybersentinelWeb.IncidentController do
  use CybersentinelWeb, :controller
  alias Cybersentinel.Incidents
  alias Cybersentinel.Guardian

  def index(conn, params) do
    incidents = Incidents.list_incidents(params)
    json(conn, %{incidents: Enum.map(incidents, &incident_json/1)})
  end

  def show(conn, %{"id" => id}) do
    incident = Incidents.get_incident!(id)
    json(conn, %{incident: incident_json(incident, detailed: true)})
  end

  @doc "Creates an incident FROM an alert. Body: {alert_id, title?, description?, severity?}"
  def create(conn, %{"alert_id" => alert_id} = params) do
    analyst = Guardian.Plug.current_resource(conn)

    case Incidents.create_incident_from_alert(alert_id, Map.drop(params, ["alert_id"]), analyst) do
      {:ok, incident} ->
        conn |> put_status(:created) |> json(%{incident: incident_json(incident)})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: errors(changeset)})
    end
  end

  @doc "Update fields and/or drive the status workflow: new -> investigating -> contained -> resolved."
  def update(conn, %{"id" => id} = params) do
    incident = Incidents.get_incident!(id)

    case Incidents.update_incident(incident, Map.drop(params, ["id"])) do
      {:ok, updated} -> json(conn, %{incident: incident_json(updated)})
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: errors(changeset)})
    end
  end

  defp incident_json(i, opts \\ []) do
    base = %{
      id: i.id,
      incident_number: i.incident_number,
      title: i.title,
      description: i.description,
      severity: i.severity,
      status: i.status,
      source_ip: i.source_ip,
      resolution_notes: i.resolution_notes,
      inserted_at: i.inserted_at,
      updated_at: i.updated_at,
      assigned_analyst: i.assigned_analyst && %{id: i.assigned_analyst.id, username: i.assigned_analyst.username}
    }

    if opts[:detailed] do
      Map.merge(base, %{
        response_actions: Enum.map(i.response_actions, &response_action_json/1),
        investigations: Enum.map(i.investigations, &investigation_json/1)
      })
    else
      base
    end
  end

  defp response_action_json(r), do: %{id: r.id, action_type: r.action_type, description: r.description, inserted_at: r.inserted_at}

  defp investigation_json(inv) do
    %{
      id: inv.id,
      started_at: inv.started_at,
      completed_at: inv.completed_at,
      conclusion: inv.conclusion,
      notes: Enum.map(inv.notes, &%{id: &1.id, note: &1.note, inserted_at: &1.inserted_at})
    }
  end

  defp errors(changeset), do: Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
end
