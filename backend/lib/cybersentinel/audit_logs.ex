defmodule Cybersentinel.AuditLogs do
  @moduledoc "Records and lists immutable audit trail entries."

  import Ecto.Query, warn: false
  alias Cybersentinel.Repo
  alias Cybersentinel.AuditLogs.AuditLog

  @doc "Writes an audit entry. Never raises into the caller's flow on failure — logs and moves on."
  def log(attrs) do
    %AuditLog{}
    |> AuditLog.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, entry} -> entry
      {:error, changeset} ->
        require Logger
        Logger.warning("audit log write failed: #{inspect(changeset.errors)}")
        nil
    end
  end

  def list_logs(params \\ %{}) do
    AuditLog
    |> maybe_filter_action(params["action"])
    |> maybe_filter_user(params["user_id"])
    |> order_by([l], desc: l.inserted_at)
    |> limit(^Map.get(params, "limit", 200))
    |> Repo.all()
    |> Repo.preload(:user)
  end

  defp maybe_filter_action(query, nil), do: query
  defp maybe_filter_action(query, action), do: where(query, [l], l.action == ^action)

  defp maybe_filter_user(query, nil), do: query
  defp maybe_filter_user(query, user_id), do: where(query, [l], l.user_id == ^user_id)
end
