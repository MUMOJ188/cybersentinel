defmodule CybersentinelWeb.AuthControllerTest do
  use CybersentinelWeb.ConnCase, async: true
  import Cybersentinel.Fixtures

  setup do
    role_fixture("administrator")
    role_fixture("security_analyst")
    role_fixture("manager")
    :ok
  end

  test "register creates a user and returns a token", %{conn: conn} do
    conn =
      post(conn, "/api/auth/register", %{
        "full_name" => "Jane Analyst",
        "username" => "janea",
        "email" => "jane@example.com",
        "password" => "Passw0rd1",
        "password_confirmation" => "Passw0rd1",
        "role_name" => "security_analyst"
      })

    body = json_response(conn, 201)
    assert body["token"]
    assert body["user"]["role"] == "security_analyst"
  end

  test "register rejects mismatched password confirmation", %{conn: conn} do
    conn =
      post(conn, "/api/auth/register", %{
        "full_name" => "Jane Analyst",
        "username" => "janeb",
        "email" => "janeb@example.com",
        "password" => "Passw0rd1",
        "password_confirmation" => "Different1",
        "role_name" => "security_analyst"
      })

    assert json_response(conn, 422)["errors"]["password"]
  end

  test "login succeeds with correct credentials", %{conn: conn} do
    user = user_fixture("manager")

    conn = post(conn, "/api/auth/login", %{"identifier" => user.email, "password" => "Passw0rd1"})
    body = json_response(conn, 200)
    assert body["token"]
    assert body["user"]["username"] == user.username
  end

  test "login fails with wrong password", %{conn: conn} do
    user = user_fixture("manager")
    conn = post(conn, "/api/auth/login", %{"identifier" => user.email, "password" => "wrong"})
    assert json_response(conn, 401)
  end

  test "an authenticated manager cannot reach admin-only routes", %{conn: conn} do
    manager = user_fixture("manager")

    conn =
      conn
      |> auth_conn(manager)
      |> get("/api/admin/users")

    assert json_response(conn, 403)
  end

  test "an authenticated manager CAN reach manager routes", %{conn: conn} do
    manager = user_fixture("manager")

    conn =
      conn
      |> auth_conn(manager)
      |> get("/api/manager/incidents")

    assert json_response(conn, 200)
  end
end
