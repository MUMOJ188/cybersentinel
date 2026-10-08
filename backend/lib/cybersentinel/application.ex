defmodule Cybersentinel.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CybersentinelWeb.Telemetry,
      Cybersentinel.Repo,
      {DNSCluster, query: Application.get_env(:cybersentinel, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Cybersentinel.PubSub},
      {Finch, name: Cybersentinel.Finch},
      CybersentinelWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Cybersentinel.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CybersentinelWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
