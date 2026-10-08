defmodule Cybersentinel.Alerts do
  @moduledoc """
  Alert lifecycle: creation (by the DetectionEngine), status transitions
  (by analysts), and the Phoenix PubSub broadcast that powers the
  real-time alert feed over Channels.
  """

  import Ecto.Query, warn: false
  alias Cybersentinel.Repo
  alias Cybersentinel.Alerts.Alert
  alias Phoenix.PubSub

  @topic "alerts:lobby"

  def topic, do: @topic

  def subscribe, do: PubSub.subscribe(Cybersentinel.PubSub, @topic)

  @doc """
  Creates an alert from a triggering security event + the rule that
  fired (rule may be nil for the blocklist-based suspicious_ip check,
  which isn't threshold/rule driven). Broadcasts `{:new_alert, alert}`
  to every subscriber (Channels forward this to connected React clients).
  """
  def create_alert(attrs) do
    %Alert{}
    |> Alert.create_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, alert} ->
        alert = Repo.preload(alert, [:security_event, :detection_rule, :user, :device])
        PubSub.broadcast(Cybersentinel.PubSub, @topic, {:new_alert, alert})
        {:ok, alert}

      error ->
        error
    end
  end

  def get_alert!(id) do
    Repo.get!(Alert, id) |> Repo.preload([:security_event, :detection_rule, :user, :device, :incident])
  end

  def list_alerts(params \\ %{}) do
    Alert
    |> maybe_filter_status(params["status"])
    |> maybe_filter_severity(params["severity"])
    |> order_by([a], desc: a.inserted_at)
    |> limit(^Map.get(params, "limit", 200))
    |> Repo.all()
    |> Repo.preload([:security_event, :detection_rule, :user, :device])
  end

  def update_status(%Alert{} = alert, status) do
    alert |> Alert.status_changeset(%{status: status}) |> Repo.update()
  end

  def acknowledge(%Alert{} = alert), do: update_status(alert, "acknowledged")

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [a], a.status == ^status)

  defp maybe_filter_severity(query, nil), do: query
  defp maybe_filter_severity(query, severity), do: where(query, [a], a.severity == ^severity)

  @doc "Counts grouped by severity, for dashboard cards."
  def counts_by_severity do
    from(a in Alert, group_by: a.severity, select: {a.severity, count(a.id)})
    |> Repo.all()
    |> Map.new()
  end
end
