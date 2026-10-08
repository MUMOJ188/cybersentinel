defmodule Cybersentinel.Accounts.PasswordResetToken do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "password_reset_tokens" do
    field(:token_hash, :string)
    field(:expires_at, :utc_datetime)
    field(:used_at, :utc_datetime)

    belongs_to(:user, Cybersentinel.Accounts.User)

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:user_id, :token_hash, :expires_at])
    |> validate_required([:user_id, :token_hash, :expires_at])
    |> unique_constraint(:token_hash)
  end
end
