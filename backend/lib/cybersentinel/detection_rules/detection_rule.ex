defmodule Cybersentinel.DetectionRules.DetectionRule do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_severities ~w(low medium high critical)

  schema "detection_rules" do
    field :name, :string
    field :event_type, :string
    field :threshold, :integer
    field :time_window_seconds, :integer
    field :severity, :string
    field :description, :string
    field :enabled, :boolean, default: true

    belongs_to :creator, Cybersentinel.Accounts.User, foreign_key: :created_by

    timestamps(type: :utc_datetime)
  end

  def valid_severities, do: @valid_severities

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [:name, :event_type, :threshold, :time_window_seconds, :severity, :description, :enabled, :created_by])
    |> validate_required([:name, :event_type, :threshold, :time_window_seconds, :severity])
    |> validate_inclusion(:event_type, Cybersentinel.SecurityEvents.SecurityEvent.valid_event_types())
    |> validate_inclusion(:severity, @valid_severities)
    |> validate_number(:threshold, greater_than: 0)
    |> validate_number(:time_window_seconds, greater_than_or_equal_to: 0)
  end
end
