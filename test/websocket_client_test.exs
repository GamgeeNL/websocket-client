defmodule WebsocketClientTest do
  use ExUnit.Case
  doctest WebsocketClient

  test "greets the world" do
    assert WebsocketClient.hello() == :world
  end
end
