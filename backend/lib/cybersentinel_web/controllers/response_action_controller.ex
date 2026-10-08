defmodule CybersentinelWeb.ResponseActionController do
  use CybersentinelWeb, :controller
  alias Cybersentinel.ResponseActions
  alias Cybersentinel.Guardian

  def index(conn, params) do
    actions = ResponseActions.list_actions(params)

    json(conn, %{
      response_actions:
        Enum.map(actions, fn a ->
          %{
            id: a.id,
            action_type: a.action_type,
            description: a.description,
            inserted_at: a.inserted_at,
            incident_id: a.incident_id,
            analyst: a.analyst && %{username: a.analyst.username}
          }
        end)
    })
  end

  @doc "Body: {incident_id, action_type, description?}"
  def create(conn, params) do
    analyst = Guardian.Plug.current_resource(conn)
    attrs = Map.put(params, "analyst_id", analyst.id)

    case ResponseActions.record_action(attrs) do
      {:ok, action} ->
        conn
        |> put_status(:created)
        |> json(%{response_action: %{id: action.id, action_type: action.action_type, description: action.description}})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: errors(changeset)})
    end
  end

  defp errors(changeset), do: Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
end
