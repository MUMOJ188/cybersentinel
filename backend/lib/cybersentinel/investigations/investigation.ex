defmodule Cybersentinel.Investigations.Investigation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "investigations" do
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :conclusion, :string

    belongs_to :incident, Cybersentinel.Incidents.Incident
    belongs_to :analyst, Cybersentinel.Accounts.User

    has_many :notes, Cybersentinel.Investigations.InvestigationNote

    timestamps(type: :utc_datetime)
  end

  def create_changeset(investigation, attrs) do
    investigation
    |> cast(attrs, [:incident_id, :analyst_id, :started_at, :completed_at, :conclusion])
    |> validate_required([:incident_id, :analyst_id, :started_at])
    |> foreign_key_constraint(:incident_id)
  end

  def update_changeset(investigation, attrs) do
    investigation
    |> cast(attrs, [:completed_at, :conclusion])
  end
end
