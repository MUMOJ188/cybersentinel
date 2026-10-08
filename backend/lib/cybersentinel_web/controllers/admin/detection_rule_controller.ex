defmodule CybersentinelWeb.Admin.DetectionRuleController do
  use CybersentinelWeb, :controller
  alias Cybersentinel.DetectionRules
  alias Cybersentinel.Guardian

  def index(conn, _params) do
    json(conn, %{rules: Enum.map(DetectionRules.list_rules(), &rule_json/1)})
  end

  def show(conn, %{"id" => id}) do
    json(conn, %{rule: rule_json(DetectionRules.get_rule!(id))})
  end

  def create(conn, params) do
    admin = Guardian.Plug.current_resource(conn)
    attrs = Map.put(params, "created_by", admin.id)

    case DetectionRules.create_rule(attrs) do
      {:ok, rule} -> conn |> put_status(:created) |> json(%{rule: rule_json(rule)})
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: errors(changeset)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    rule = DetectionRules.get_rule!(id)

    case DetectionRules.update_rule(rule, Map.drop(params, ["id"])) do
      {:ok, updated} -> json(conn, %{rule: rule_json(updated)})
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    rule = DetectionRules.get_rule!(id)
    {:ok, _} = DetectionRules.delete_rule(rule)
    send_resp(conn, :no_content, "")
  end

  defp rule_json(r) do
    %{
      id: r.id,
      name: r.name,
      event_type: r.event_type,
      threshold: r.threshold,
      time_window_seconds: r.time_window_seconds,
      severity: r.severity,
      description: r.description,
      enabled: r.enabled
    }
  end

  defp errors(changeset), do: Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
end
