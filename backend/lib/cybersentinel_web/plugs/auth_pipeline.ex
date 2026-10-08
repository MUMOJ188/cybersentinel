defmodule CybersentinelWeb.Plugs.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :cybersentinel,
    module: Cybersentinel.Guardian,
    error_handler: CybersentinelWeb.Plugs.AuthErrorHandler

  # Expects "Authorization: Bearer <token>"
  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
