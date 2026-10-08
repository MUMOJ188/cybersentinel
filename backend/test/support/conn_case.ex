defmodule CybersentinelWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import CybersentinelWeb.ConnCase

      alias CybersentinelWeb.Router.Helpers, as: Routes

      @endpoint CybersentinelWeb.Endpoint
    end
  end

  setup tags do
    Cybersentinel.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
