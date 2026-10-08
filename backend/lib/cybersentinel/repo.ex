defmodule Cybersentinel.Repo do
  use Ecto.Repo,
    otp_app: :cybersentinel,
    adapter: Ecto.Adapters.Postgres
end
