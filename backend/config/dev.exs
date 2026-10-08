import Config

# Supabase connection string, e.g.:
# postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    Set it to your Supabase connection string, e.g.
    export DATABASE_URL="postgresql://postgres:PASSWORD@db.PROJECT_REF.supabase.co:5432/postgres"
    """

config :cybersentinel, Cybersentinel.Repo,
  url: database_url,
  ssl: true,
  ssl_opts: [verify: :verify_none],
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :cybersentinel, CybersentinelWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: System.get_env("SECRET_KEY_BASE") || "dev_secret_key_base_at_least_64_bytes_long_0000000000000000000",
  watchers: []

config :cybersentinel, dev_routes: true

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
