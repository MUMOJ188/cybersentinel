defmodule Cybersentinel.Repo.Migrations.CreateIpBlocklist do
  use Ecto.Migration

  def change do
    create table(:ip_blocklist, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ip_address, :string, null: false
      add :description, :text
      add :enabled, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:ip_blocklist, [:ip_address])
  end
end
