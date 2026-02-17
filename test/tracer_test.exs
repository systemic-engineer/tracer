defmodule TracerTest do
  use ExUnit.Case, async: true

  doctest Tracer
  doctest Tracer.Nesting
  doctest Inspect.Tracer
end
