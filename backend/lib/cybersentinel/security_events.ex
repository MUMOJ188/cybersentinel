defmodule Cybersentinel.SecurityEvents do
  @moduledoc "Ingests security events (from the simulator, later from real feeds) and queries them."

  import Ecto.Query, warn: false
  alias Cybersentinel.Repo
  alias Cybersentinel.SecurityEvents.{SecurityEvent, Device}

  ## Events

  def create_event(attrs) do
    %SecurityEvent{}
    |> SecurityEvent.changeset(attrs)
    |> Repo.insert()
  end

  def get_event!(id), do: Repo.get!(SecurityEvent, id) |> Repo.preload([:user, :device])

  def list_events(params \\ %{}) do
    SecurityEvent
    |> maybe_filter_type(params["event_type"])
    |> maybe_filter_ip(params["source_ip"])
    |> order_by([e], desc: e.occurred_at)
    |> limit(^Map.get(params, "limit", 200))
    |> Repo.all()
    |> Repo.preload([:user, :device])
  end

  @doc "Events of `event_type` from `source_ip` in the last `window_seconds`, most recent first."
  def recent_events_by_type_and_ip(event_type, source_ip, window_seconds) do
    since = DateTime.add(DateTime.utc_now(), -window_seconds, :second)

    from(e in SecurityEvent,
      where: e.event_type == ^event_type and e.source_ip == ^source_ip and e.occurred_at >= ^since,
      order_by: [desc: e.occurred_at]
    )
    |> Repo.all()
  end

  @doc "Count of distinct `target` values (used for port-scan: distinct destination ports) for an IP/type/window."
  def distinct_target_count_by_type_and_ip(event_type, source_ip, window_seconds) do
    since = DateTime.add(DateTime.utc_now(), -window_seconds, :second)

    from(e in SecurityEvent,
      where: e.event_type == ^event_type and e.source_ip == ^source_ip and e.occurred_at >= ^since,
      select: count(fragment("DISTINCT ?", e.target))
    )
    |> Repo.one()
  end

  def recent_events_by_type_and_user(event_type, user_id, window_seconds) do
    since = DateTime.add(DateTime.utc_now(), -window_seconds, :second)

    from(e in SecurityEvent,
      where: e.event_type == ^event_type and e.user_id == ^user_id and e.occurred_at >= ^since,
      order_by: [desc: e.occurred_at]
    )
    |> Repo.all()
  end

  defp maybe_filter_type(query, nil), do: query
  defp maybe_filter_type(query, type), do: where(query, [e], e.event_type == ^type)

  defp maybe_filter_ip(query, nil), do: query
  defp maybe_filter_ip(query, ip), do: where(query, [e], e.source_ip == ^ip)

  ## Devices

  def get_device_by_identifier(user_id, device_identifier) do
    Repo.get_by(Device, user_id: user_id, device_identifier: device_identifier)
  end

  def list_known_devices(user_id) do
    from(d in Device, where: d.user_id == ^user_id and d.is_known == true) |> Repo.all()
  end

  @doc """
  Returns `{:known, device}` if the user already has this device on file,
  or `{:unknown, device}` after recording it as a new, not-yet-trusted device
  (this is what the unknown_device_login rule keys off).
  """
  def register_or_check_device(user_id, device_identifier, attrs \\ %{}) do
    case get_device_by_identifier(user_id, device_identifier) do
      nil ->
        changeset =
          Device.changeset(
            %Device{},
            Map.merge(attrs, %{
              "user_id" => user_id,
              "device_identifier" => device_identifier,
              "is_known" => false,
              "last_seen_at" => DateTime.utc_now() |> DateTime.truncate(:second)
            })
          )

        case Repo.insert(changeset) do
          {:ok, device} -> {:unknown, device}
          {:error, _} = err -> err
        end

      %Device{is_known: true} = device ->
        {:known, device}

      %Device{is_known: false} = device ->
        {:unknown, device}
    end
  end

  def mark_device_known(%Device{} = device) do
    device |> Device.changeset(%{"is_known" => true}) |> Repo.update()
  end
end
