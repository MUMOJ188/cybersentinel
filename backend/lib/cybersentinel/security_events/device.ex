defmodule Cybersentinel.SecurityEvents.Device do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "devices" do
    field :device_identifier, :string
    field :device_name, :string
    field :device_type, :string
    field :is_known, :boolean, default: true
    field :last_seen_at, :utc_datetime

    belongs_to :user, Cybersentinel.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(device, attrs) do
    device
    |> cast(attrs, [:user_id, :device_identifier, :device_name, :device_type, :is_known, :last_seen_at])
    |> validate_required([:user_id, :device_identifier])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :device_identifier])
  end
end
