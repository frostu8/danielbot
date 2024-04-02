defmodule Danielbot.Consumer do
  use Nostrum.Consumer

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    Danielbot.Interaction.handle_interaction(interaction)
  end
end
