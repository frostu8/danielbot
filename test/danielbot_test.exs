defmodule DanielbotTest do
  use ExUnit.Case
  doctest Danielbot

  test "greets the world" do
    assert Danielbot.hello() == :world
  end
end
