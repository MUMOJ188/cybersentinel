defmodule Cybersentinel.Fixtures do
  alias Cybersentinel.Repo
  alias Cybersentinel.Accounts
  alias Cybersentinel.Accounts.Role

  def role_fixture(name) do
    Repo.get_by(Role, name: name) || Repo.insert!(%Role{name: name})
  end

  def user_fixture(role_name, attrs \\ %{}) do
    role_fixture(role_name)

    base = %{
      "full_name" => "Test User",
      "username" => "user#{System.unique_integer([:positive])}",
      "email" => "user#{System.unique_integer([:positive])}@example.com",
      "password" => "Passw0rd1",
      "password_confirmation" => "Passw0rd1",
      "role_name" => role_name
    }

    {:ok, user} = Accounts.register_user(Map.merge(base, attrs))
    user
  end

  def auth_conn(conn, user) do
    {:ok, token, _claims} = Cybersentinel.Guardian.issue_token(user)
    Plug.Conn.put_req_header(conn, "authorization", "Bearer #{token}")
  end
end
