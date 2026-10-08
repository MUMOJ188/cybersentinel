defmodule Cybersentinel.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Cybersentinel.Repo
      import Ecto
      import Ecto.Query
      import Cybersentinel.DataCase
    end
  end

  setup tags do
    Cybersentinel.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Cybersentinel.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
