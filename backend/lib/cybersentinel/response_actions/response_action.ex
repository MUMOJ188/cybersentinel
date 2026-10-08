defmodule Cybersentinel.ResponseActions.ResponseAction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_action_types ~w(
    account_locked password_reset_requested ip_blocked
    device_isolated access_revoked investigation_completed
  )

  schema "response_actions" do
    field :action_type, :string
    field :description, :string

    belongs_to :incident, Cybersentinel.Incidents.Incident
    belongs_to :analyst, Cybersentinel.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def valid_action_types, do: @valid_action_types

  def changeset(action, attrs) do
    action
    |> cast(attrs, [:incident_id, :analyst_id, :action_type, :description])
    |> validate_required([:incident_id, :analyst_id, :action_type])
    |> validate_inclusion(:action_type, @valid_action_types)
    |> foreign_key_constraint(:incident_id)
  end
end
