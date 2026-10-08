defmodule Cybersentinel.MixProject do
  use Mix.Project

  def project do
    [
      app: :cybersentinel,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Cybersentinel.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.11"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.16"},
      {:finch, "~> 0.18"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.24"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.1.1"},
      {:plug_cowboy, "~> 2.7"},
      # Auth & security
      {:pbkdf2_elixir, "~> 2.0"},
      {:guardian, "~> 2.3"},
      {:cors_plug, "~> 3.0"},
      # Rate limiting
      {:hammer, "~> 6.2"},
      # Background jobs (optional, used for cleanup / scheduled reports)
      {:oban, "~> 2.18"},
      # CSV/UUID helpers
      {:ecto_psql_extras, "~> 0.8", only: :dev}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end