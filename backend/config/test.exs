import Config

database_url =
  System.get_env("TEST_DATABASE_URL") || System.get_env("DATABASE_URL") ||
    raise "environment variable DATABASE_URL (or TEST_DATABASE_URL) is missing"

config :cybersentinel, Cybersentinel.Repo,
  url: database_url,
  ssl: true,
  ssl_opts: [verify: :verify_none],
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :cybersentinel, CybersentinelWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_at_least_64_bytes_long_00000000000000000000000",
  server: false

config :cybersentinel, Cybersentinel.Guardian, secret_key: "test_guardian_secret"

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
config :pbkdf2_elixir, :rounds, 1