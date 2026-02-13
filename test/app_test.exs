defmodule {{module_name}}Test do
  use ExUnit.Case
  doctest {{module_name}}

  test "hello/0 returns :world" do
    assert {{module_name}}.hello() == :world
  end
end
