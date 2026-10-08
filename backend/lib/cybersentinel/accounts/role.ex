defmodule Cybersentinel.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_roles ~w(administrator security_analyst manager)

  schema "roles" do
    field :name, :string

    has_many :users, Cybersentinel.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def valid_roles, do: @valid_roles

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_inclusion(:name, @valid_roles)
    |> unique_constraint(:name)
  end
end
