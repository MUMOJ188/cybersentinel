defmodule Cybersentinel.DetectionRules do
  @moduledoc "CRUD for detection rules, and lookups the DetectionEngine uses at evaluation time."

  import Ecto.Query, warn: false
  alias Cybersentinel.Repo
  alias Cybersentinel.DetectionRules.DetectionRule

  def list_rules, do: Repo.all(DetectionRule) |> Repo.preload(:creator)

  def get_rule!(id), do: Repo.get!(DetectionRule, id) |> Repo.preload(:creator)

  def enabled_rules_for_event_type(event_type) do
    from(r in DetectionRule, where: r.event_type == ^event_type and r.enabled == true)
    |> Repo.all()
  end

  def create_rule(attrs) do
    %DetectionRule{} |> DetectionRule.changeset(attrs) |> Repo.insert()
  end

  def update_rule(%DetectionRule{} = rule, attrs) do
    rule |> DetectionRule.changeset(attrs) |> Repo.update()
  end

  def delete_rule(%DetectionRule{} = rule), do: Repo.delete(rule)

  def count_active, do: Repo.aggregate(from(r in DetectionRule, where: r.enabled == true), :count)
end
