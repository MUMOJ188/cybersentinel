import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "environment variable DATABASE_URL is missing (Supabase connection string)"

  config :cybersentinel, Cybersentinel.Repo,
    url: database_url,
    ssl: true,
    ssl_opts: [verify: :verify_none],
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing. Generate with: mix phx.gen.secret"

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :cybersentinel, CybersentinelWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base

  config :cybersentinel, Cybersentinel.Guardian,
    secret_key: System.get_env("GUARDIAN_SECRET_KEY") ||
      raise("environment variable GUARDIAN_SECRET_KEY is missing")
end
