defmodule DalgoTest do
  use ExUnit.Case
  doctest Dalgo

  test "greets the world" do
    assert Dalgo.hello() == :world
  end
end
