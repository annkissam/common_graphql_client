defmodule CommonGraphqlClientTest do
  use ExUnit.Case
  doctest CommonGraphqlClient

  test "greets the world" do
    assert CommonGraphqlClient.hello() == :world
  end
end
