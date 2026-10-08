defmodule Cybersentinel.Alerts.Alert do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_statuses ~w(new acknowledged investigating resolved false_positive)
  @valid_severities ~w(low medium high critical)

  schema "alerts" do
    field :alert_type, :string
    field :severity, :string
    field :source_ip, :string
    field :description, :string
    field :status, :string, default: "new"

    belongs_to :security_event, Cybersentinel.SecurityEvents.SecurityEvent
    belongs_to :detection_rule, Cybersentinel.DetectionRules.DetectionRule
    belongs_to :user, Cybersentinel.Accounts.User
    belongs_to :device, Cybersentinel.SecurityEvents.Device

    has_one :incident, Cybersentinel.Incidents.Incident

    timestamps(type: :utc_datetime)
  end

  def valid_statuses, do: @valid_statuses

  def create_changeset(alert, attrs) do
    alert
    |> cast(attrs, [
      :alert_type, :severity, :security_event_id, :detection_rule_id,
      :source_ip, :user_id, :device_id, :description, :status
    ])
    |> validate_required([:alert_type, :severity, :security_event_id])
    |> validate_inclusion(:severity, @valid_severities)
    |> validate_inclusion(:status, @valid_statuses)
    |> foreign_key_constraint(:security_event_id)
  end

  def status_changeset(alert, attrs) do
    alert
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, @valid_statuses)
  end
end
