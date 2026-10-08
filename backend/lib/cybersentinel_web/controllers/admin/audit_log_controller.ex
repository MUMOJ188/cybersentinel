defmodule CybersentinelWeb.Admin.AuditLogController do
  use CybersentinelWeb, :controller
  alias Cybersentinel.AuditLogs

  def index(conn, params) do
    logs = AuditLogs.list_logs(params)

    json(conn, %{
      logs:
        Enum.map(logs, fn l ->
          %{
            id: l.id,
            action: l.action,
            resource_type: l.resource_type,
            resource_id: l.resource_id,
            description: l.description,
            ip_address: l.ip_address,
            inserted_at: l.inserted_at,
            user: l.user && %{id: l.user.id, username: l.user.username}
          }
        end)
    })
  end
end
