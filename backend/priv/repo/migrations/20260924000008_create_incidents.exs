defmodule Cybersentinel.Repo.Migrations.CreateIncidents do
  use Ecto.Migration

  def change do
    create table(:incidents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :incident_number, :string, null: false
      add :title, :string, null: false
      add :description, :text
      add :severity, :string, null: false
      add :alert_id, references(:alerts, type: :binary_id, on_delete: :nilify_all)
      add :source_ip, :string
      add :affected_user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :affected_device_id, references(:devices, type: :binary_id, on_delete: :nilify_all)
      add :assigned_analyst_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :status, :string, null: false, default: "new"
      add :resolution_notes, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:incidents, [:incident_number])
    create index(:incidents, [:status])
    create index(:incidents, [:assigned_analyst_id])
    create index(:incidents, [:alert_id])
  end
end
