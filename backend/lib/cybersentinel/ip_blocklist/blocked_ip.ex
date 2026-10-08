defmodule Cybersentinel.IpBlocklist.BlockedIp do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "ip_blocklist" do
    field :ip_address, :string
    field :description, :string
    field :enabled, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:ip_address, :description, :enabled])
    |> validate_required([:ip_address])
    |> unique_constraint(:ip_address)
  end
end
