import Config

import_config "secret.exs"

config :danielbot, ecto_repos: [Danielbot.Repo]

config :danielbot, Danielbot.Repo,
  database: "db/database.db"
