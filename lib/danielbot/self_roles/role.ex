defmodule Danielbot.SelfRoles.Role do
  use Ecto.Schema

  import Ecto.Changeset

  schema "self_roles" do
    field :guild_id, :integer
    field :role_id, :integer
    field :label, :string
    field :emoji, :string
  end

  def changeset(role, params \\ %{}) do
    role
    |> cast(params, [:role_id, :emoji, :guild_id])
    |> unique_constraint([:role_id, :guild_id])
    |> validate_required([:guild_id, :role_id, :label])
  end
end
