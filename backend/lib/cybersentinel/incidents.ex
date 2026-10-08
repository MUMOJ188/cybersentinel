defmodule Cybersentinel.Incidents do
  import Ecto.Query, warn: false
  alias Cybersentinel.Repo
  alias Cybersentinel.Incidents.Incident
  alias Cybersentinel.Alerts

  def list_incidents(params \\ %{}) do
    Incident
    |> maybe_filter_status(params["status"])
    |> order_by([i], desc: i.inserted_at)
    |> limit(^Map.get(params, "limit", 200))
    |> Repo.all()
    |> Repo.preload([:alert, :affected_user, :affected_device, :assigned_analyst])
  end

  def get_incident!(id) do
    Repo.get!(Incident, id)
    |> Repo.preload([
      :affected_user, :affected_device, :assigned_analyst,
      :response_actions,
      alert: [:security_event, :detection_rule],
      investigations: [:analyst, :notes]
    ])
  end

  @doc """
  Creates an incident FROM an alert (an alert is never automatically an
  incident — this is the explicit analyst action that promotes it), and
  moves the alert into "investigating".
  """
  def create_incident_from_alert(alert_id, attrs, analyst) do
    alert = Alerts.get_alert!(alert_id)

    incident_attrs =
      attrs
      |> Map.put("incident_number", next_incident_number())
      |> Map.put("alert_id", alert.id)
      |> Map.put("source_ip", alert.source_ip)
      |> Map.put("affected_user_id", alert.user_id)
      |> Map.put("affected_device_id", alert.device_id)
      |> Map.put_new("assigned_analyst_id", analyst.id)
      |> Map.put_new("severity", alert.severity)
      |> Map.put_new("title", humanize_alert_type(alert.alert_type))
      |> Map.put_new("status", "new")

    Repo.transaction(fn ->
      case %Incident{} |> Incident.create_changeset(incident_attrs) |> Repo.insert() do
        {:ok, incident} ->
          Alerts.update_status(alert, "investigating")
          incident

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def update_incident(%Incident{} = incident, attrs) do
    incident |> Incident.update_changeset(attrs) |> Repo.update()
  end

  def transition_status(%Incident{} = incident, status) when status in ["new", "investigating", "contained", "resolved"] do
    update_incident(incident, %{"status" => status})
  end

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [i], i.status == ^status)

  defp next_incident_number do
    count = Repo.aggregate(Incident, :count) + 1
    "INC-" <> String.pad_leading(Integer.to_string(count), 4, "0")
  end

  defp humanize_alert_type(type), do: type |> String.replace("_", " ") |> String.capitalize()

  ## Reporting helpers (Manager dashboards / reports)

  def counts_by_status do
    from(i in Incident, group_by: i.status, select: {i.status, count(i.id)})
    |> Repo.all()
    |> Map.new()
  end

  def counts_by_severity do
    from(i in Incident, group_by: i.severity, select: {i.severity, count(i.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc "Average seconds from incident creation to resolution, among resolved incidents."
  def average_resolution_seconds do
    from(i in Incident,
      where: i.status == "resolved",
      select: avg(fragment("EXTRACT(EPOCH FROM (?::timestamp - ?::timestamp))", i.updated_at, i.inserted_at))
    )
    |> Repo.one()
  end
end
