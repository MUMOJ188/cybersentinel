defmodule Cybersentinel.Repo.Migrations.CreateInvestigations do
  use Ecto.Migration

  def change do
    create table(:investigations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :incident_id, references(:incidents, type: :binary_id, on_delete: :delete_all), null: false
      add :analyst_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false
      add :started_at, :utc_datetime, null: false
      add :completed_at, :utc_datetime
      add :conclusion, :text

      timestamps(type: :utc_datetime)
    end

    create index(:investigations, [:incident_id])
    create index(:investigations, [:analyst_id])
  end
end
