defmodule CybersentinelWeb.Admin.UserController do
  use CybersentinelWeb, :controller
  alias Cybersentinel.Accounts

  def index(conn, _params) do
    users = Accounts.list_users()
    json(conn, %{users: Enum.map(users, &user_json/1)})
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    json(conn, %{user: user_json(user)})
  end

  @doc "Update full_name / status / role_id (admin reassigns role or disables an account)."
  def update(conn, %{"id" => id} = params) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, Map.drop(params, ["id"])) do
      {:ok, updated} -> json(conn, %{user: user_json(updated)})
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: errors(changeset)})
    end
  end

  def set_status(conn, %{"id" => id, "status" => status}) when status in ["active", "disabled"] do
    user = Accounts.get_user!(id)

    case Accounts.set_user_status(user, status) do
      {:ok, updated} -> json(conn, %{user: user_json(updated)})
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: errors(changeset)})
    end
  end

  defp user_json(u) do
    %{
      id: u.id,
      full_name: u.full_name,
      username: u.username,
      email: u.email,
      status: u.status,
      role: u.role && u.role.name,
      inserted_at: u.inserted_at
    }
  end

  defp errors(changeset), do: Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
end
