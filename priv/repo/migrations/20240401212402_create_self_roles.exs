defmodule Danielbot.Repo.Migrations.CreateSelfRoles do
  use Ecto.Migration

  def change do
    create table(:self_roles) do
      add :guild_id, :integer
      add :role_id, :integer
      add :label, :string
      add :emoji, :string
    end

    create unique_index(:self_roles, [:guild_id, :role_id])
  end
end
