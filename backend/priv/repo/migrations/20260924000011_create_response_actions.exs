defmodule Cybersentinel.Repo.Migrations.CreateResponseActions do
  use Ecto.Migration

  def change do
    create table(:response_actions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :incident_id, references(:incidents, type: :binary_id, on_delete: :delete_all), null: false
      add :analyst_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false
      add :action_type, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:response_actions, [:incident_id])
  end
end
