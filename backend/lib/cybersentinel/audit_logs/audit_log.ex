defmodule Cybersentinel.AuditLogs.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audit_logs" do
    field :action, :string
    field :resource_type, :string
    field :resource_id, :binary_id
    field :description, :string
    field :ip_address, :string

    belongs_to :user, Cybersentinel.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:user_id, :action, :resource_type, :resource_id, :description, :ip_address])
    |> validate_required([:action])
  end
end
