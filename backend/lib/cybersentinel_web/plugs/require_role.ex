defmodule CybersentinelWeb.Plugs.RequireRole do
  @moduledoc """
  Plug: `plug CybersentinelWeb.Plugs.RequireRole, ["administrator"]`

  Must run after AuthPipeline (which loads the current_user via Guardian).
  Rejects the request with 403 if the authenticated user's role is not
  in the allowed list. This is the enforcement point that guarantees a
  user cannot reach another role's endpoints by hitting the URL directly
  or forging a frontend route — the check happens on the server, not
  just in the React router.
  """
  import Plug.Conn
  alias Cybersentinel.Accounts

  def init(allowed_roles), do: allowed_roles

  def call(conn, allowed_roles) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        deny(conn)

      user ->
        if Accounts.role_name(user) in allowed_roles do
          conn
        else
          deny(conn)
        end
    end
  end

  defp deny(conn) do
    body = Jason.encode!(%{error: "forbidden", details: "insufficient role"})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(403, body)
    |> halt()
  end
end
