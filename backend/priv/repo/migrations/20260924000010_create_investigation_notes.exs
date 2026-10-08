defmodule Cybersentinel.Repo.Migrations.CreateInvestigationNotes do
  use Ecto.Migration

  def change do
    create table(:investigation_notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :investigation_id, references(:investigations, type: :binary_id, on_delete: :delete_all), null: false
      add :analyst_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false
      add :note, :text, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:investigation_notes, [:investigation_id])
  end
end
