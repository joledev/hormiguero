defmodule Hormiguero.Repo do
  use Ecto.Repo,
    otp_app: :hormiguero,
    adapter: Ecto.Adapters.Postgres
end
