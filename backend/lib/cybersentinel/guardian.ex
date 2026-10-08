defmodule Cybersentinel.Guardian do
  use Guardian, otp_app: :cybersentinel

  alias Cybersentinel.Accounts

  def subject_for_token(%Cybersentinel.Accounts.User{id: id}, _claims), do: {:ok, id}
  def subject_for_token(_, _), do: {:error, :invalid_resource}

  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_claims), do: {:error, :invalid_claims}

  @doc "Issues a short-lived access token carrying the user's role for fast plug checks."
  def issue_token(user) do
    encode_and_sign(user, %{"role" => Accounts.role_name(user)}, token_type: "access", ttl: {8, :hours})
  end
end
