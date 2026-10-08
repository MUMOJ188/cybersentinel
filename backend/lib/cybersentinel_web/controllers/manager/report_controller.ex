defmodule CybersentinelWeb.Manager.ReportController do
  use CybersentinelWeb, :controller
  alias Cybersentinel.{Incidents, Alerts, SecurityEvents, Repo}
  import Ecto.Query

  def summary(conn, _params) do
    avg_seconds = Incidents.average_resolution_seconds()

    json(conn, %{
      total_security_events: Repo.aggregate(Cybersentinel.SecurityEvents.SecurityEvent, :count),
      total_alerts: Repo.aggregate(Cybersentinel.Alerts.Alert, :count),
      incidents_by_status: Incidents.counts_by_status(),
      incidents_by_severity: Incidents.counts_by_severity(),
      alerts_by_severity: Alerts.counts_by_severity(),
      average_response_time_seconds: round_seconds(avg_seconds)
    })
  end

  @doc "Daily counts of events and alerts over the last 14 days, for a trend chart."
  def trends(conn, _params) do
    since = DateTime.add(DateTime.utc_now(), -14 * 86_400, :second)

    events_by_day =
      from(e in Cybersentinel.SecurityEvents.SecurityEvent,
        where: e.occurred_at >= ^since,
        group_by: fragment("date(?)", e.occurred_at),
        select: {fragment("date(?)", e.occurred_at), count(e.id)},
        order_by: fragment("date(?)", e.occurred_at)
      )
      |> Repo.all()

    alerts_by_day =
      from(a in Cybersentinel.Alerts.Alert,
        where: a.inserted_at >= ^since,
        group_by: fragment("date(?)", a.inserted_at),
        select: {fragment("date(?)", a.inserted_at), count(a.id)},
        order_by: fragment("date(?)", a.inserted_at)
      )
      |> Repo.all()

    json(conn, %{
      events_by_day: Enum.map(events_by_day, fn {d, c} -> %{date: d, count: c} end),
      alerts_by_day: Enum.map(alerts_by_day, fn {d, c} -> %{date: d, count: c} end)
    })
  end

  @doc """
  Metrics scoped to a daily / weekly / monthly window, for the
  downloadable PDF report. The PDF itself is built on the frontend;
  this just returns the numbers for the chosen period.
  """
  def export(conn, params) do
    period = Map.get(params, "period", "daily")
    {since, until, label} = range_for(period)

    total_events =
      Repo.aggregate(
        from(e in Cybersentinel.SecurityEvents.SecurityEvent,
          where: e.occurred_at >= ^since and e.occurred_at <= ^until
        ),
        :count
      )

    total_alerts =
      Repo.aggregate(
        from(a in Cybersentinel.Alerts.Alert,
          where: a.inserted_at >= ^since and a.inserted_at <= ^until
        ),
        :count
      )

    critical_alerts =
      Repo.aggregate(
        from(a in Cybersentinel.Alerts.Alert,
          where: a.inserted_at >= ^since and a.inserted_at <= ^until and a.severity == "critical"
        ),
        :count
      )

    high_alerts =
      Repo.aggregate(
        from(a in Cybersentinel.Alerts.Alert,
          where: a.inserted_at >= ^since and a.inserted_at <= ^until and a.severity == "high"
        ),
        :count
      )

    new_incidents =
      Repo.aggregate(
        from(i in Cybersentinel.Incidents.Incident,
          where: i.inserted_at >= ^since and i.inserted_at <= ^until
        ),
        :count
      )

    resolved_incidents =
      Repo.aggregate(
        from(i in Cybersentinel.Incidents.Incident,
          where: i.status == "resolved" and i.updated_at >= ^since and i.updated_at <= ^until
        ),
        :count
      )

    avg_seconds =
      from(i in Cybersentinel.Incidents.Incident,
        where: i.status == "resolved" and i.updated_at >= ^since and i.updated_at <= ^until,
        select:
          avg(fragment("EXTRACT(EPOCH FROM (?::timestamp - ?::timestamp))", i.updated_at, i.inserted_at))
      )
      |> Repo.one()

    most_common_alert_type =
      from(a in Cybersentinel.Alerts.Alert,
        where: a.inserted_at >= ^since and a.inserted_at <= ^until,
        group_by: a.alert_type,
        select: {a.alert_type, count(a.id)},
        order_by: [desc: count(a.id)],
        limit: 1
      )
      |> Repo.one()
      |> case do
        {type, _count} -> type
        nil -> "N/A"
      end

    json(conn, %{
      period: period,
      period_label: label,
      generated_at: DateTime.utc_now(),
      range_start: since,
      range_end: until,
      total_security_events: total_events,
      total_alerts: total_alerts,
      critical_alerts: critical_alerts,
      high_alerts: high_alerts,
      new_incidents: new_incidents,
      resolved_incidents: resolved_incidents,
      average_response_time_seconds: round_seconds(avg_seconds),
      most_common_alert_type: most_common_alert_type
    })
  end

  defp range_for("weekly") do
    until = DateTime.utc_now()
    since = DateTime.add(until, -7 * 86_400, :second)
    {since, until, "Weekly"}
  end

  defp range_for("monthly") do
    until = DateTime.utc_now()
    since = DateTime.add(until, -30 * 86_400, :second)
    {since, until, "Monthly"}
  end

  defp range_for(_daily) do
    until = DateTime.utc_now()
    since = DateTime.new!(DateTime.to_date(until), ~T[00:00:00], "Etc/UTC")
    {since, until, "Daily"}
  end

  defp round_seconds(nil), do: nil
  defp round_seconds(%Decimal{} = d), do: d |> Decimal.to_float() |> round()
  defp round_seconds(n) when is_number(n), do: round(n)
end