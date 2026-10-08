defmodule CybersentinelWeb.AuthController do
  use CybersentinelWeb, :controller

  alias Cybersentinel.Accounts
  alias Cybersentinel.AuditLogs
  alias Cybersentinel.Guardian

  # --- Rate limiting config: 10 attempts / 5 minutes per IP on auth endpoints ---
  @rate_limit_scale_ms 5 * 60 * 1000
  @rate_limit_max_attempts 10

  def register(conn, params) do
    case Accounts.register_user(params) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.issue_token(user)

        AuditLogs.log(%{
          user_id: user.id,
          action: "user_registered",
          resource_type: "user",
          resource_id: user.id,
          description: "#{user.username} registered as #{Accounts.role_name(user)}",
          ip_address: client_ip(conn)
        })

        conn
        |> put_status(:created)
        |> json(%{token: token, user: user_json(user)})

      {:error, :invalid_role} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: %{role: ["is invalid"]}})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: translate_errors(changeset)})
    end
  end

  def login(conn, %{"identifier" => identifier, "password" => password}) do
    rate_limit_key = "login:#{client_ip(conn)}"

    case Hammer.check_rate(rate_limit_key, @rate_limit_scale_ms, @rate_limit_max_attempts) do
      {:allow, _count} ->
        do_login(conn, identifier, password)

      {:deny, _limit} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "too_many_attempts", details: "try again later"})
    end
  end

  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "identifier and password are required"})
  end

  def forgot_password(conn, %{"email" => email}) do
    rate_limit_key = "forgot_password:#{client_ip(conn)}"

    case Hammer.check_rate(rate_limit_key, @rate_limit_scale_ms, @rate_limit_max_attempts) do
      {:allow, _count} ->
        frontend_url = System.get_env("FRONTEND_URL") || "http://localhost:5173"
        build_url = fn token -> "#{frontend_url}/reset-password?token=#{token}" end

        Accounts.request_password_reset(email, build_url)

        json(conn, %{
          status: "ok",
          message: "If an account exists for that email, a reset link has been sent."
        })

      {:deny, _limit} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "too_many_attempts", details: "try again later"})
    end
  end

  def forgot_password(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "email is required"})
  end

  def reset_password_with_token(conn, %{"token" => token} = params) do
    case Accounts.reset_password_with_token(token, params) do
      {:ok, _user} ->
        json(conn, %{status: "ok"})

      {:error, :invalid_or_expired} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "invalid_or_expired_token"})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: translate_errors(changeset)})
    end
  end

  def reset_password_with_token(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "token is required"})
  end

  defp do_login(conn, identifier, password) do
    case Accounts.authenticate(identifier, password) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.issue_token(user)

        AuditLogs.log(%{
          user_id: user.id,
          action: "user_login",
          resource_type: "user",
          resource_id: user.id,
          description: "#{user.username} logged in",
          ip_address: client_ip(conn)
        })

        json(conn, %{token: token, user: user_json(user)})

      {:error, :account_disabled} ->
        conn |> put_status(:forbidden) |> json(%{error: "account_disabled"})

      {:error, :invalid_credentials} ->
        conn |> put_status(:unauthorized) |> json(%{error: "invalid_credentials"})
    end
  end

  def logout(conn, _params) do
    token = Guardian.Plug.current_token(conn)
    Guardian.revoke(token)
    send_resp(conn, :no_content, "")
  end

  def me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    json(conn, %{user: user_json(user)})
  end

  def reset_password(conn, params) do
    user = Guardian.Plug.current_resource(conn)

    case Accounts.reset_password(user, params) do
      {:ok, updated_user} ->
        AuditLogs.log(%{
          user_id: updated_user.id,
          action: "password_reset",
          resource_type: "user",
          resource_id: updated_user.id,
          description: "#{updated_user.username} reset their password",
          ip_address: client_ip(conn)
        })

        json(conn, %{status: "ok"})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: translate_errors(changeset)})
    end
  end

  defp user_json(user) do
    %{
      id: user.id,
      full_name: user.full_name,
      username: user.username,
      email: user.email,
      role: Accounts.role_name(user),
      status: user.status
    }
  end

  defp client_ip(conn) do
    conn.remote_ip |> :inet.ntoa() |> to_string()
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
