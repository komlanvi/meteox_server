defmodule MeteoxServerTest do
  use ExUnit.Case
  doctest MeteoxServer

  test "greets the world" do
    assert MeteoxServer.hello() == :world
  end
end
