defmodule Cybersentinel.Repo.Migrations.CreateDetectionRules do
  use Ecto.Migration

  def change do
    create table(:detection_rules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :event_type, :string, null: false
      add :threshold, :integer, null: false
      add :time_window_seconds, :integer, null: false
      add :severity, :string, null: false
      add :description, :text
      add :enabled, :boolean, null: false, default: true
      add :created_by, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:detection_rules, [:event_type])
    create index(:detection_rules, [:enabled])
  end
end
