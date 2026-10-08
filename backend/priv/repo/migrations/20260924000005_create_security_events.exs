defmodule Cybersentinel.Repo.Migrations.CreateSecurityEvents do
  use Ecto.Migration

  def change do
    create table(:security_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_type, :string, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :source_ip, :string
      add :destination_ip, :string
      add :device_id, references(:devices, type: :binary_id, on_delete: :nilify_all)
      add :target, :string
      add :description, :text
      add :metadata, :map, null: false, default: %{}
      add :occurred_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:security_events, [:event_type])
    create index(:security_events, [:source_ip])
    create index(:security_events, [:user_id])
    create index(:security_events, [:occurred_at])
    create index(:security_events, [:event_type, :source_ip, :occurred_at])
  end
end
