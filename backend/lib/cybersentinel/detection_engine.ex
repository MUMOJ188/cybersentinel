defmodule Cybersentinel.DetectionEngine do
  @moduledoc """
  SecurityEvent -> DetectionEngine -> Matching Rules -> Alert

  `evaluate/1` is called (synchronously, from the Simulation controller in
  Stage 3, right after a security event is inserted) with the freshly
  created `%SecurityEvent{}`. It runs every applicable check and creates
  whatever alerts fire. This module never touches real infrastructure —
  it only reads/writes rows in the security tables.
  """

  import Ecto.Query, warn: false
  alias Cybersentinel.Repo
  alias Cybersentinel.{SecurityEvents, DetectionRules, Alerts, IpBlocklist}
  alias Cybersentinel.Alerts.Alert

  @doc "Runs every rule relevant to this event's type, plus the always-on blocklist check."
  def evaluate(security_event) do
    results = []

    results = results ++ List.wrap(check_blocklist(security_event))

    results =
      results ++
        case security_event.event_type do
          "failed_login" -> List.wrap(check_threshold_rule(security_event, "failed_login", by: :source_ip))
          "port_scan" -> List.wrap(check_port_scan(security_event))
          "large_data_transfer" -> List.wrap(check_large_transfer(security_event))
          "access_denied" -> List.wrap(check_threshold_rule(security_event, "access_denied", by: :user_id))
          "unknown_device_login" -> List.wrap(check_unknown_device(security_event))
          "suspicious_ip" -> List.wrap(check_explicit_suspicious_ip(security_event))
          _ -> []
        end

    Enum.reject(results, &is_nil/1)
  end

  ## Rule 3 (always-on): source_ip is in ip_blocklist

  defp check_blocklist(%{source_ip: nil}), do: nil

  defp check_blocklist(event) do
    if IpBlocklist.blocked?(event.source_ip) and not already_alerted?(nil, event.source_ip, "suspicious_ip") do
      Alerts.create_alert(%{
        alert_type: "suspicious_ip",
        severity: "high",
        security_event_id: event.id,
        detection_rule_id: nil,
        source_ip: event.source_ip,
        user_id: event.user_id,
        device_id: event.device_id,
        description: "Source IP #{event.source_ip} matches an entry in the IP blocklist.",
        status: "new"
      })
      |> unwrap()
    end
  end

  defp check_explicit_suspicious_ip(event), do: check_blocklist(event)

  ## Rules 1 & 5: generic "N events of this type from the same key within window" -> alert

  defp check_threshold_rule(event, event_type, by: key_field) do
    key_value = Map.get(event, key_field)
    if is_nil(key_value), do: nil, else: run_threshold_rules(event, event_type, key_field, key_value)
  end

  defp run_threshold_rules(event, event_type, key_field, key_value) do
    DetectionRules.enabled_rules_for_event_type(event_type)
    |> Enum.map(fn rule ->
      count =
        case key_field do
          :source_ip ->
            length(SecurityEvents.recent_events_by_type_and_ip(event_type, key_value, rule.time_window_seconds))

          :user_id ->
            length(SecurityEvents.recent_events_by_type_and_user(event_type, key_value, rule.time_window_seconds))
        end

      if count >= rule.threshold and not already_alerted?(rule.id, event.source_ip, rule_key(event_type)) do
        {label, description} = threshold_alert_copy(event_type, count, event, rule)

        Alerts.create_alert(%{
          alert_type: label,
          severity: rule.severity,
          security_event_id: event.id,
          detection_rule_id: rule.id,
          source_ip: event.source_ip,
          user_id: event.user_id,
          device_id: event.device_id,
          description: description,
          status: "new"
        })
        |> unwrap()
      end
    end)
  end

  defp threshold_alert_copy("failed_login", count, event, rule) do
    {"possible_brute_force",
     "#{count} failed login attempts from #{event.source_ip} within #{rule.time_window_seconds}s " <>
       "(threshold: #{rule.threshold}). Possible brute-force attack."}
  end

  defp threshold_alert_copy("access_denied", count, event, rule) do
    {"repeated_unauthorized_access",
     "#{count} access-denied events from user #{event.user_id} within #{rule.time_window_seconds}s " <>
       "(threshold: #{rule.threshold}). Repeated unauthorized access attempts."}
  end

  defp rule_key("failed_login"), do: "possible_brute_force"
  defp rule_key("access_denied"), do: "repeated_unauthorized_access"

  ## Rule 2: port scan — many distinct target ports from the same source IP in a window

  defp check_port_scan(%{source_ip: nil}), do: nil

  defp check_port_scan(event) do
    DetectionRules.enabled_rules_for_event_type("port_scan")
    |> Enum.map(fn rule ->
      distinct_ports =
        SecurityEvents.distinct_target_count_by_type_and_ip("port_scan", event.source_ip, rule.time_window_seconds)

      if distinct_ports >= rule.threshold and not already_alerted?(rule.id, event.source_ip, "possible_port_scan") do
        Alerts.create_alert(%{
          alert_type: "possible_port_scan",
          severity: rule.severity,
          security_event_id: event.id,
          detection_rule_id: rule.id,
          source_ip: event.source_ip,
          user_id: event.user_id,
          device_id: event.device_id,
          description:
            "#{distinct_ports} distinct ports probed from #{event.source_ip} within " <>
              "#{rule.time_window_seconds}s (threshold: #{rule.threshold}). Possible port scan.",
          status: "new"
        })
        |> unwrap()
      end
    end)
  end

  ## Rule 4: large data transfer — single event, bytes over threshold

  defp check_large_transfer(event) do
    bytes = get_in(event.metadata, ["bytes_transferred"]) || 0
    bytes = if is_binary(bytes), do: String.to_integer(bytes), else: bytes

    DetectionRules.enabled_rules_for_event_type("large_data_transfer")
    |> Enum.map(fn rule ->
      if bytes >= rule.threshold do
        Alerts.create_alert(%{
          alert_type: "unusual_data_transfer",
          severity: rule.severity,
          security_event_id: event.id,
          detection_rule_id: rule.id,
          source_ip: event.source_ip,
          user_id: event.user_id,
          device_id: event.device_id,
          description:
            "Transfer of #{bytes} bytes exceeds threshold of #{rule.threshold} bytes. Unusual data transfer.",
          status: "new"
        })
        |> unwrap()
      end
    end)
  end

  ## Rule 6: unknown device login — single event, device not on the user's known list

  defp check_unknown_device(event) do
    if get_in(event.metadata, ["known_device"]) == false do
      DetectionRules.enabled_rules_for_event_type("unknown_device_login")
      |> Enum.map(fn rule ->
        Alerts.create_alert(%{
          alert_type: "suspicious_login_device",
          severity: rule.severity,
          security_event_id: event.id,
          detection_rule_id: rule.id,
          source_ip: event.source_ip,
          user_id: event.user_id,
          device_id: event.device_id,
          description: "Login from a device not on file for this user. Suspicious login device.",
          status: "new"
        })
        |> unwrap()
      end)
    end
  end

  ## Dedup: don't re-fire the same rule for the same source IP repeatedly while
  ## the underlying condition is still true — one alert per episode.

  defp already_alerted?(rule_id, source_ip, alert_type) do
    from(a in Alert,
      where: a.alert_type == ^alert_type and a.status not in ["resolved", "false_positive"],
      where: ^dedup_scope(rule_id, source_ip)
    )
    |> Repo.exists?()
  end

  defp dedup_scope(nil, source_ip), do: dynamic([a], a.source_ip == ^source_ip)
  defp dedup_scope(rule_id, source_ip), do: dynamic([a], a.detection_rule_id == ^rule_id and a.source_ip == ^source_ip)

  defp unwrap({:ok, alert}), do: alert
  defp unwrap({:error, _} = err), do: err
end
