defmodule Cybersentinel.SecurityEvents.SecurityEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_event_types ~w(
    failed_login port_scan suspicious_ip large_data_transfer
    access_denied unknown_device_login
  )

  schema "security_events" do
    field :event_type, :string
    field :source_ip, :string
    field :destination_ip, :string
    field :target, :string
    field :description, :string
    field :metadata, :map, default: %{}
    field :occurred_at, :utc_datetime

    belongs_to :user, Cybersentinel.Accounts.User
    belongs_to :device, Cybersentinel.SecurityEvents.Device

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def valid_event_types, do: @valid_event_types

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :event_type, :user_id, :source_ip, :destination_ip, :device_id,
      :target, :description, :metadata, :occurred_at
    ])
    |> validate_required([:event_type, :occurred_at])
    |> validate_inclusion(:event_type, @valid_event_types)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:device_id)
  end
end
