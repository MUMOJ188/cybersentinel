defmodule Cybersentinel.IpBlocklist do
  import Ecto.Query, warn: false
  alias Cybersentinel.Repo
  alias Cybersentinel.IpBlocklist.BlockedIp

  def list_entries, do: Repo.all(BlockedIp)

  def blocked?(nil), do: false

  def blocked?(ip_address) do
    Repo.exists?(from b in BlockedIp, where: b.ip_address == ^ip_address and b.enabled == true)
  end

  def add(attrs), do: %BlockedIp{} |> BlockedIp.changeset(attrs) |> Repo.insert()

  def remove(%BlockedIp{} = entry), do: Repo.delete(entry)
end
