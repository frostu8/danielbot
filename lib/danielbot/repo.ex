defmodule Danielbot.Repo do
  use Ecto.Repo,
    otp_app: :danielbot,
    adapter: Ecto.Adapters.SQLite3
end
