defmodule Cybersentinel.ResponseActions do
  @moduledoc """
  Records response actions taken against an incident. These are always
  SIMULATED/RECORDED entries for this controlled demo — creating one
  never contacts a real firewall, IAM system, or device. It's an audit
  trail of what an analyst decided to do.
  """

  import Ecto.Query, warn: false
  alias Cybersentinel.Repo
  alias Cybersentinel.ResponseActions.ResponseAction

  def list_actions(params \\ %{}) do
    ResponseAction
    |> maybe_filter_incident(params["incident_id"])
    |> order_by([r], desc: r.inserted_at)
    |> Repo.all()
    |> Repo.preload([:incident, :analyst])
  end

  def record_action(attrs) do
    %ResponseAction{} |> ResponseAction.changeset(attrs) |> Repo.insert()
  end

  defp maybe_filter_incident(query, nil), do: query
  defp maybe_filter_incident(query, incident_id), do: where(query, [r], r.incident_id == ^incident_id)
end
