defmodule Cybersentinel.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :alert_type, :string, null: false
      add :severity, :string, null: false
      add :security_event_id, references(:security_events, type: :binary_id, on_delete: :delete_all), null: false
      add :detection_rule_id, references(:detection_rules, type: :binary_id, on_delete: :nilify_all)
      add :source_ip, :string
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :device_id, references(:devices, type: :binary_id, on_delete: :nilify_all)
      add :description, :text
      add :status, :string, null: false, default: "new"

      timestamps(type: :utc_datetime)
    end

    create index(:alerts, [:status])
    create index(:alerts, [:severity])
    create index(:alerts, [:security_event_id])
    create index(:alerts, [:detection_rule_id])
  end
end
