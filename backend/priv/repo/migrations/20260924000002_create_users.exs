defmodule Cybersentinel.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :full_name, :string, null: false
      add :username, :string, null: false
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :role_id, references(:roles, type: :binary_id, on_delete: :restrict), null: false
      add :status, :string, null: false, default: "active"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
    create index(:users, [:role_id])
    create index(:users, [:status])
  end
end
