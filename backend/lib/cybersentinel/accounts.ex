defmodule Cybersentinel.Accounts do
  @moduledoc """
  The Accounts context: user registration, authentication, role
  management, and admin user administration.
  """

  import Ecto.Query, warn: false
  alias Cybersentinel.Repo
  alias Cybersentinel.Accounts.PasswordResetToken
  alias Cybersentinel.Accounts.{User, Role}

  @reset_token_ttl_seconds 3600

  ## Roles

  def list_roles, do: Repo.all(Role)

  def get_role_by_name(name), do: Repo.get_by(Role, name: name)

  def get_role!(id), do: Repo.get!(Role, id)

  ## Users - queries

  def list_users, do: Repo.all(User) |> Repo.preload(:role)

  def get_user!(id), do: Repo.get!(User, id) |> Repo.preload(:role)

  def get_user(id), do: Repo.get(User, id) |> maybe_preload_role()

  def get_user_by_email(email), do: Repo.get_by(User, email: email) |> maybe_preload_role()

  def get_user_by_username(username),
    do: Repo.get_by(User, username: username) |> maybe_preload_role()

  @doc "Login accepts either an email or a username in the same field."
  def get_user_by_identifier(identifier) do
    Repo.one(
      from(u in User,
        where: u.email == ^identifier or u.username == ^identifier
      )
    )
    |> maybe_preload_role()
  end

  defp maybe_preload_role(nil), do: nil
  defp maybe_preload_role(user), do: Repo.preload(user, :role)

  ## Registration

  @doc """
  Registers a new user. `attrs` must include `role_name` (one of
  "administrator" | "security_analyst" | "manager"), which is resolved
  to a role_id server-side — the client never sends a role_id directly.
  """
  def register_user(attrs) do
    role_name = attrs["role_name"] || attrs[:role_name]

    with %Role{id: role_id} <- get_role_by_name(role_name) do
      attrs =
        attrs
        |> to_string_keyed_map()
        |> Map.put("role_id", role_id)

      %User{}
      |> User.registration_changeset(attrs)
      |> Repo.insert()
    else
      nil -> {:error, :invalid_role}
    end
  end

  defp to_string_keyed_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  ## Authentication

  @doc """
  Verifies credentials. Always runs the hash check (even for unknown
  users, against a dummy hash) to avoid leaking user existence via
  response timing.
  """
  def authenticate(identifier, password) do
    user = get_user_by_identifier(identifier)

    cond do
      user && user.status != "active" ->
        {:error, :account_disabled}

      user && Pbkdf2.verify_pass(password, user.password_hash) ->
        {:ok, user}

      true ->
        Pbkdf2.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  ## Admin management

  def update_user(%User{} = user, attrs) do
    user
    |> User.admin_update_changeset(attrs)
    |> Repo.update()
  end

  def set_user_status(%User{} = user, status) when status in ["active", "disabled"] do
    update_user(user, %{
      "status" => status,
      "full_name" => user.full_name,
      "role_id" => user.role_id
    })
  end

  def reset_password(%User{} = user, attrs) do
    user
    |> User.password_reset_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Starts a password reset for the given email. Always returns :ok,
  whether or not the email matches an account, so this endpoint never
  reveals which emails are registered.
  """
  def request_password_reset(email, build_reset_url) do
    case get_user_by_email(email) do
      nil ->
        :ok

      user ->
        raw_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
        token_hash = :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower)

        %PasswordResetToken{}
        |> PasswordResetToken.changeset(%{
          user_id: user.id,
          token_hash: token_hash,
          expires_at: DateTime.add(DateTime.utc_now(), @reset_token_ttl_seconds, :second)
        })
        |> Repo.insert()
        |> case do
          {:ok, _token} ->
            Cybersentinel.UserNotifier.deliver_password_reset(user, build_reset_url.(raw_token))
            :ok

          {:error, _changeset} ->
            :ok
        end
    end
  end

  @doc "Verifies a raw reset token is valid and unused, returning the associated user."
  def get_user_by_reset_token(raw_token) do
    token_hash = :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower)
    now = DateTime.utc_now()

    query =
      from(t in PasswordResetToken,
        where: t.token_hash == ^token_hash and is_nil(t.used_at) and t.expires_at > ^now,
        select: t
      )

    case Repo.one(query) do
      nil -> {:error, :invalid_or_expired}
      token -> {:ok, get_user!(token.user_id), token}
    end
  end

  @doc "Resets the password using a valid token, and marks the token used so it can't be replayed."
  def reset_password_with_token(raw_token, attrs) do
    with {:ok, user, token} <- get_user_by_reset_token(raw_token) do
      Repo.transaction(fn ->
        case reset_password(user, attrs) do
          {:ok, updated_user} ->
            token
            |> Ecto.Changeset.change(used_at: DateTime.utc_now() |> DateTime.truncate(:second))
            |> Repo.update!()

            updated_user

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
    end
  end

  def role_name(%User{} = user) do
    user = maybe_preload_role(user)
    user.role.name
  end
end
