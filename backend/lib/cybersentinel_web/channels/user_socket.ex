defmodule CybersentinelWeb.UserSocket do
  use Phoenix.Socket

  channel "alerts:lobby", CybersentinelWeb.AlertChannel

  @doc """
  React connects with `new Socket("/socket", {params: {token}})`. The
  same Guardian JWT issued at login is reused here so the socket is tied
  to an authenticated user — no anonymous alert stream.
  """
  def connect(%{"token" => token}, socket, _connect_info) do
    case Cybersentinel.Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        case Cybersentinel.Guardian.resource_from_claims(claims) do
          {:ok, user} -> {:ok, assign(socket, :current_user, user)}
          _ -> :error
        end

      _ ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"
end
