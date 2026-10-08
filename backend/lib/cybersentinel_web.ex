defmodule CybersentinelWeb do
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]
      import Plug.Conn
      alias Cybersentinel.Repo
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def json_view do
    quote do
      import Phoenix.Controller, only: [json: 2]
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
