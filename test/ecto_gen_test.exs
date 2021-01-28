defmodule EctoGenTest do
  use ExUnit.Case
  doctest EctoGen

  test "greets the world" do
    assert EctoGen.hello() == :world
  end
end
