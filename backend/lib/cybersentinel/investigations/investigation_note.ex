defmodule Cybersentinel.Investigations.InvestigationNote do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "investigation_notes" do
    field :note, :string

    belongs_to :investigation, Cybersentinel.Investigations.Investigation
    belongs_to :analyst, Cybersentinel.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(note, attrs) do
    note
    |> cast(attrs, [:investigation_id, :analyst_id, :note])
    |> validate_required([:investigation_id, :analyst_id, :note])
    |> foreign_key_constraint(:investigation_id)
  end
end
