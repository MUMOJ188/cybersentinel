defmodule CybersentinelWeb.InvestigationController do
  use CybersentinelWeb, :controller
  alias Cybersentinel.Investigations
  alias Cybersentinel.Guardian

  def index(conn, params) do
    json(conn, %{investigations: Enum.map(Investigations.list_investigations(params), &investigation_json/1)})
  end

  def show(conn, %{"id" => id}) do
    json(conn, %{investigation: investigation_json(Investigations.get_investigation!(id))})
  end

  @doc "Body: {incident_id}. Analyst is taken from the auth token."
  def create(conn, %{"incident_id" => incident_id}) do
    analyst = Guardian.Plug.current_resource(conn)

    case Investigations.start_investigation(%{"incident_id" => incident_id, "analyst_id" => analyst.id}) do
      {:ok, investigation} -> conn |> put_status(:created) |> json(%{investigation: investigation_json(investigation)})
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: errors(changeset)})
    end
  end

  @doc "Body: {conclusion} — marks the investigation complete."
  def update(conn, %{"id" => id} = params) do
    investigation = Investigations.get_investigation!(id)

    case Investigations.complete_investigation(investigation, params["conclusion"]) do
      {:ok, updated} -> json(conn, %{investigation: investigation_json(updated)})
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: errors(changeset)})
    end
  end

  def add_note(conn, %{"id" => investigation_id, "note" => note_text}) do
    analyst = Guardian.Plug.current_resource(conn)

    case Investigations.add_note(investigation_id, analyst.id, note_text) do
      {:ok, note} -> conn |> put_status(:created) |> json(%{note: %{id: note.id, note: note.note, inserted_at: note.inserted_at}})
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: errors(changeset)})
    end
  end

  defp investigation_json(inv) do
    %{
      id: inv.id,
      incident_id: inv.incident_id,
      started_at: inv.started_at,
      completed_at: inv.completed_at,
      conclusion: inv.conclusion,
      analyst: inv.analyst && %{id: inv.analyst.id, username: inv.analyst.username},
      notes: Enum.map(inv.notes, &%{id: &1.id, note: &1.note, inserted_at: &1.inserted_at})
    }
  end

  defp errors(changeset), do: Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
end
