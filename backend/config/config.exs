import Config

config :cybersentinel,
  ecto_repos: [Cybersentinel.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :cybersentinel, CybersentinelWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [json: CybersentinelWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Cybersentinel.PubSub,
  live_view: [signing_salt: "cybersentinel_salt"]

config :cybersentinel, Cybersentinel.Guardian,
  issuer: "cybersentinel",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY") || "dev_only_secret_change_me"

config :cybersentinel, Cybersentinel.Mailer, adapter: Swoosh.Adapters.Local

config :swoosh, :api_client, false

config :esbuild,
  version: "0.21.5",
  default: [
    args: ~w(js/app.js --bundle --target=es2020 --outdir=../priv/static/assets/js),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

# Rate limiting backend (in-memory ETS; swap for Redis in prod if needed)
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

config :cybersentinel, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10, reports: 5],
  repo: Cybersentinel.Repo

import_config "#{config_env()}.exs"