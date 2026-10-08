defmodule Cybersentinel.Investigations do
  import Ecto.Query, warn: false
  alias Cybersentinel.Repo
  alias Cybersentinel.Investigations.{Investigation, InvestigationNote}

  def list_investigations(params \\ %{}) do
    Investigation
    |> maybe_filter_incident(params["incident_id"])
    |> order_by([i], desc: i.inserted_at)
    |> Repo.all()
    |> Repo.preload([:analyst, :notes, :incident])
  end

  def get_investigation!(id) do
    Repo.get!(Investigation, id) |> Repo.preload([:analyst, :notes, :incident])
  end

  def start_investigation(attrs) do
    attrs = Map.put_new(attrs, "started_at", DateTime.utc_now() |> DateTime.truncate(:second))

    %Investigation{}
    |> Investigation.create_changeset(attrs)
    |> Repo.insert()
  end

  def complete_investigation(%Investigation{} = investigation, conclusion) do
    investigation
    |> Investigation.update_changeset(%{
      "completed_at" => DateTime.utc_now() |> DateTime.truncate(:second),
      "conclusion" => conclusion
    })
    |> Repo.update()
  end

  def add_note(investigation_id, analyst_id, note_text) do
    %InvestigationNote{}
    |> InvestigationNote.changeset(%{
      "investigation_id" => investigation_id,
      "analyst_id" => analyst_id,
      "note" => note_text
    })
    |> Repo.insert()
  end

  defp maybe_filter_incident(query, nil), do: query
  defp maybe_filter_incident(query, incident_id), do: where(query, [i], i.incident_id == ^incident_id)
end
