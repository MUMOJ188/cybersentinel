defmodule Cybersentinel.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :full_name, :string
    field :username, :string
    field :email, :string
    field :password_hash, :string
    field :status, :string, default: "active"

    # virtual fields, never persisted
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    belongs_to :role, Cybersentinel.Accounts.Role
    has_many :devices, Cybersentinel.SecurityEvents.Device
    has_many :audit_logs, Cybersentinel.AuditLogs.AuditLog

    timestamps(type: :utc_datetime)
  end

  @doc "Used for self-registration. Requires password + confirmation + role."
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:full_name, :username, :email, :password, :password_confirmation, :role_id])
    |> validate_required([:full_name, :username, :email, :password, :password_confirmation, :role_id])
    |> validate_length(:full_name, min: 2, max: 120)
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/, message: "only letters, numbers, underscore")
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:password, min: 8, max: 72)
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password_strength()
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> foreign_key_constraint(:role_id)
    |> put_password_hash()
  end

  @doc "Used by administrators to update role/status without touching password."
  def admin_update_changeset(user, attrs) do
    user
    |> cast(attrs, [:full_name, :status, :role_id])
    |> validate_required([:full_name, :status, :role_id])
    |> validate_inclusion(:status, ~w(active disabled))
    |> foreign_key_constraint(:role_id)
  end

  def password_reset_changeset(user, attrs) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 8, max: 72)
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password_strength()
    |> put_password_hash()
  end

  defp validate_password_strength(changeset) do
    validate_change(changeset, :password, fn :password, password ->
      cond do
        not Regex.match?(~r/[A-Z]/, password) -> [password: "must contain an uppercase letter"]
        not Regex.match?(~r/[a-z]/, password) -> [password: "must contain a lowercase letter"]
        not Regex.match?(~r/[0-9]/, password) -> [password: "must contain a number"]
        true -> []
      end
    end)
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end
