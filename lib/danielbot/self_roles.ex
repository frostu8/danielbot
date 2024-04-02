defmodule Danielbot.SelfRoles do
  @moduledoc """
  All the selfroles logic.
  """

  alias Nostrum.Struct.Interaction
  alias Nostrum.Struct.Guild.Role

  alias Nostrum.Constants
  alias Nostrum.Api

  alias Danielbot.Repo

  @type emoji() :: %{id: integer(), name: String.t(), animated: boolean()}

  @doc "Posts selfroles as an interaction response"
  @spec post_self_roles(Interaction.t()) :: {:ok} | Api.error()
  def post_self_roles(interaction) do
    roles = get_self_roles(interaction.guild_id)

    buttons = Enum.map(roles, fn role ->
      # parse emoji
      emoji = emoji_from_db(role.emoji)

      %{
        type: Constants.ComponentType.button(),
        label: role.label,
        style: Constants.ButtonStyle.secondary(),
        custom_id: to_string(role.id),
        emoji: emoji
      }
    end)

    res = %{
      type: Constants.InteractionCallbackType.channel_message_with_source(),
      data: %{
        content: "Select roles:",
        components: [
          %{
            type: Constants.ComponentType.action_row(),
            components: buttons
          }
        ]
      }
    }

    Api.create_interaction_response(interaction, res)
  end

  @doc "Adds a selfrole to a guild."
  @spec add_self_role(Guild.t(), Role.id(), String.t(), emoji() | nil) :: :ok | {:error, Ecto.Changeset.t()}
  def add_self_role(guild_id, role_id, label, emoji \\ nil) do
    # serialize emoji
    emoji = case emoji do
      nil ->
        nil
      emoji ->
        if emoji.animated do
          "a:#{emoji.name}:#{emoji.id}"
        else
          "#{emoji.name}:#{emoji.id}"
        end
    end

    role = %Danielbot.SelfRoles.Role{
      guild_id: guild_id,
      role_id: role_id,
      label: label,
      emoji: emoji,
    }

    role = Danielbot.SelfRoles.Role.changeset(role, %{})

    case Repo.insert(role) do
      {:ok, _} ->
        :ok
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc "Gets all selfroles in a guild."
  @spec get_self_roles(Guild.t()) :: [Danielbot.SelfRoles.Role.t()]
  def get_self_roles(guild_id) do
    import Ecto.Query

    query = from r in Danielbot.SelfRoles.Role,
      where: r.guild_id == ^guild_id

    Repo.all(query)
  end

  @doc "Gets a selfrole by its id."
  @spec get_self_role(integer()) :: Danielbot.SelfRoles.Role.t() | nil
  def get_self_role(id) do
    Repo.get_by(Danielbot.SelfRoles.Role, id: id)
  end

  @doc "Removes a selfrole from a guild."
  @spec remove_self_role(Guild.t(), Role.t()) :: :ok | :error
  def remove_self_role(guild_id, role_id) do
    case Repo.get_by(Danielbot.SelfRoles.Role, [role_id: role_id, guild_id: guild_id]) do
      nil ->
        :error
      role ->
        Repo.delete(role)
        :ok
    end
  end

  # /selfrole add <role> <label> [emoji]
  @spec handle_command_selfrole(%Interaction{}, map()) :: {:ok} | Api.error()
  def handle_command_selfrole(interaction, %{name: "add", options: options}) do
    role_id = options
    |> Enum.filter(fn x -> x.name == "role" end)
    |> Enum.map(fn x -> x.value end)
    |> Enum.at(0)
    label = options
    |> Enum.filter(fn x -> x.name == "label" end)
    |> Enum.map(fn x -> x.value end)
    |> Enum.at(0)
    emoji = options
    |> Enum.filter(fn x -> x.name == "emoji" end)
    |> Enum.map(fn x -> parse_emoji(x.value) end)
    |> Enum.at(0)

    # check if selfrole doesn't exist
    selfrole = Repo.get_by(Danielbot.SelfRoles.Role, [role_id: role_id, guild_id: interaction.guild_id])

    res = case selfrole do
      nil -> 
        # create selfrole
        Danielbot.SelfRoles.add_self_role(interaction.guild_id, role_id, label, emoji)
        "Added selfrole #{label} (role id: #{role_id})"
      _selfrole ->
        "Selfrole is already assigned for role #{role_id}\nIf you wish to reassign, first remove the old one."
    end

    Api.create_interaction_response(
      interaction,
      %{
        type: Constants.InteractionCallbackType.channel_message_with_source(),
        data: %{content: res}
      }
    )
  end

  # /selfrole remove <role>
  def handle_command_selfrole(interaction, %{name: "remove", options: options}) do
    role_id = options
    |> Enum.filter(fn x -> x.name == "role" end)
    |> Enum.map(fn x -> x.value end)
    |> Enum.at(0)

    # verify selfrole exists
    selfrole = Repo.get_by(Danielbot.SelfRoles.Role, [role_id: role_id, guild_id: interaction.guild_id])

    res = case selfrole do
      nil ->
        "Selfrole is not assigned. Nothing done."
      selfrole ->
        Repo.delete(selfrole)
        "Removed selfrole."
    end

    Api.create_interaction_response(
      interaction,
      %{
        type: Constants.InteractionCallbackType.channel_message_with_source(),
        data: %{content: res}
      }
    )
  end

  @spec parse_emoji(String.t()) :: emoji() | nil
  defp parse_emoji(emoji) do
    # discord emojis are in the format:
    #   unicode: as is
    #   custom: <a?:name:id>

    emoji
    |> String.trim
    |> String.slice(1..-2)
    |> emoji_from_db
  end

  @spec emoji_from_db(String.t()) :: emoji() | nil
  defp emoji_from_db(nil) do
    nil
  end

  defp emoji_from_db(emoji) do
    inner = emoji
    |> String.split(":", parts: 3, trim: true)

    IO.inspect inner
    if Enum.count(inner) === 3 do
      # this is an animated emoji
      {id, _rest} = Integer.parse(Enum.at(inner, 2))
      %{id: id, name: Enum.at(inner, 1), animated: true}
    else
      if Enum.count(inner) === 2 do
        {id, _rest} = Integer.parse(Enum.at(inner, 1))
        %{id: id, name: Enum.at(inner, 0), animated: false}
      else
        nil
      end
    end
  end
end
