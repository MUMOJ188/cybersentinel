defmodule Cybersentinel.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :device_identifier, :string, null: false
      add :device_name, :string
      add :device_type, :string
      add :is_known, :boolean, null: false, default: true
      add :last_seen_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:devices, [:user_id])
    create unique_index(:devices, [:user_id, :device_identifier])
  end
end
