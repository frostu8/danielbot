defmodule Danielbot.Interaction do
  alias Nostrum.Api
  alias Nostrum.Constants

  alias Nostrum.Struct.Interaction
  alias Nostrum.Struct.Guild

  import Bitwise

  @spec commands() :: map()
  def commands() do
    [
      %{
        type: Constants.ApplicationCommandType.chat_input(),
        name: "selfrole",
        description: "modify selfroles in guild",
        default_member_permissions: "0",
        options: [
          %{
            type: Constants.ApplicationCommandOptionType.sub_command(),
            name: "add",
            description: "adds a selfrole to the guild",
            options: [
              %{
                type: Constants.ApplicationCommandOptionType.role(),
                name: "role",
                description: "role to allow users to self-govern",
                required: true
              },
              %{
                type: Constants.ApplicationCommandOptionType.string(),
                name: "label",
                description: "label to display the role as",
                required: true
              },
              %{
                type: Constants.ApplicationCommandOptionType.string(),
                name: "emoji",
                description: "emoji to display with the role",
                required: false
              }
            ]
          },
          %{
            type: Constants.ApplicationCommandOptionType.sub_command(),
            name: "remove",
            description: "removes a selfrole from the guild",
            options: [
              %{
                type: Constants.ApplicationCommandOptionType.role(),
                name: "role",
                description: "role to disallow users to self-govern",
                required: true
              }
            ]
          }
        ]
      },
      %{
        name: "roles",
        description: "displays all selfroles in a menu",
      }
    ]
  end

  @spec apply_global_commands() :: any()
  def apply_global_commands() do
    commands()
    |> Enum.each(fn command -> Api.create_global_application_command(command) end)
  end

  @spec apply_guild_commands(Guild.id()) :: any()
  def apply_guild_commands(guild_id) do
    commands()
    |> Enum.each(fn command -> Api.create_guild_application_command(guild_id, command) end)
  end

  @spec handle_interaction(Interaction.t()) :: any()
  def handle_interaction(%Interaction{type: 3, data: %{custom_id: custom_id}, member: member} = interaction) do
    # parse custom id; this is a selfroles thing
    {selfrole_id, _rest} = Integer.parse(custom_id)

    case Danielbot.SelfRoles.get_self_role(selfrole_id) do
      nil ->
        # do nothing
        :ok
      role ->
        # assign/remove role
        has_role = member.roles
        |> Enum.any?(fn rid -> rid == role.role_id end)

        res = if has_role do
          # take away role
          Api.modify_guild_member!(
            interaction.guild_id,
            member.user_id,
            roles: Enum.filter(member.roles, fn rid -> rid != role.role_id end)
          )

          "Removed role <@&#{role.role_id}>"
        else
          # assign role
          Api.modify_guild_member!(
            interaction.guild_id,
            member.user_id,
            roles: [role.role_id | member.roles]
          )

          "Assigned role <@&#{role.role_id}>"
        end

        Api.create_interaction_response(
          interaction,
          %{
            type: Constants.InteractionCallbackType.channel_message_with_source(),
            data: %{content: res, flags: 1 <<< 6}
          }
        )
    end
  end

  # /selfrole
  def handle_interaction(%Interaction{type: 2, data: %{name: "selfrole", options: [options | _]}} = interaction) do
    Danielbot.SelfRoles.handle_command_selfrole(interaction, options)
  end

  # /roles
  def handle_interaction(%Interaction{type: 2, data: %{name: "roles"}} = interaction) do
    Danielbot.SelfRoles.post_self_roles(interaction)
  end

  def handle_interaction(_interaction) do
  end
end
