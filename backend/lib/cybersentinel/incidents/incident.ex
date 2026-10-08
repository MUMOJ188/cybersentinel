defmodule Cybersentinel.Incidents.Incident do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_statuses ~w(new investigating contained resolved)
  @valid_severities ~w(low medium high critical)

  schema "incidents" do
    field :incident_number, :string
    field :title, :string
    field :description, :string
    field :severity, :string
    field :source_ip, :string
    field :status, :string, default: "new"
    field :resolution_notes, :string

    belongs_to :alert, Cybersentinel.Alerts.Alert
    belongs_to :affected_user, Cybersentinel.Accounts.User
    belongs_to :affected_device, Cybersentinel.SecurityEvents.Device
    belongs_to :assigned_analyst, Cybersentinel.Accounts.User

    has_many :investigations, Cybersentinel.Investigations.Investigation
    has_many :response_actions, Cybersentinel.ResponseActions.ResponseAction

    timestamps(type: :utc_datetime)
  end

  def valid_statuses, do: @valid_statuses

  def create_changeset(incident, attrs) do
    incident
    |> cast(attrs, [
      :incident_number, :title, :description, :severity, :alert_id, :source_ip,
      :affected_user_id, :affected_device_id, :assigned_analyst_id, :status
    ])
    |> validate_required([:incident_number, :title, :severity])
    |> validate_inclusion(:severity, @valid_severities)
    |> validate_inclusion(:status, @valid_statuses)
    |> unique_constraint(:incident_number)
  end

  def update_changeset(incident, attrs) do
    incident
    |> cast(attrs, [:title, :description, :severity, :status, :assigned_analyst_id, :resolution_notes])
    |> validate_inclusion(:severity, @valid_severities)
    |> validate_inclusion(:status, @valid_statuses)
  end
end
