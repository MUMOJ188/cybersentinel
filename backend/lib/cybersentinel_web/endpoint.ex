defmodule CybersentinelWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :cybersentinel

  @session_options [
    store: :cookie,
    key: "_cybersentinel_key",
    signing_salt: "cybersentinel_signing_salt",
    same_site: "Lax"
  ]

  socket "/socket", CybersentinelWeb.UserSocket,
    websocket: true,
    longpoll: false

  plug Plug.Static,
    at: "/",
    from: :cybersentinel,
    gzip: false,
    only: CybersentinelWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  plug CORSPlug,
    origin: ["http://localhost:5173", "http://127.0.0.1:5173", "http://127.0.0.1:5174"],
    credentials: true,
    headers: ["Authorization", "Content-Type"]

  plug CybersentinelWeb.Router
end
