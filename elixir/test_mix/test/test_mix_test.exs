defmodule TestMixTest do
  use ExUnit.Case
  doctest TestMix

  test "greets the world" do
    assert TestMix.hello() == :world
  end
end
