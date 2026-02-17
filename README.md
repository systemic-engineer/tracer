# Tracer

Generic computation trace with visual tree rendering.

`Tracer` records what ran, what went in, what came out, and any
sub-steps — then renders the whole tree as a color-coded inspection output.

## Installation

```elixir
def deps do
  [
    {:tracer, "~> 0.1", github: "systemic-engineer/tracer"}
  ]
end
```

## Usage

```elixir
# Build a trace manually
trace = Tracer.new(:parse_int, "42", {:ok, 42})
Tracer.ok?(trace)     # => true
Tracer.result(trace)  # => {:ok, 42}

# Nested traces — full computation tree
inner = Tracer.new(:validate_range, 42, {:ok, 42})
outer = Tracer.new(:parse_and_validate, "42", {:ok, 42}, [inner])

# Inspect with depth control
Tracer.inspect(outer, depth: :infinity)
# Tracer<OK> {
#   data = "42"
#   :parse_and_validate
#   | :validate_range |=< 42 |=> 42
#
#   |=> 42
# }

# Only show error branches
Tracer.inspect(outer, depth: :error)

# Find failing traces anywhere in the tree
Tracer.find(outer, &Tracer.error?/1)

# Find the root causes (leaf errors)
Tracer.root_causes(outer)
```

## Inspect Options

```elixir
# depth: 0          — top level only (default)
# depth: N          — show N levels deep
# depth: :error     — only error branches
# depth: :infinity  — the full tree
inspect(trace, custom_options: [depth: :infinity])

# Or use the shortcut
Tracer.inspect(trace, depth: :infinity)
```

## Building Nested Traces

`Tracer.Nesting` helps collect traces while evaluating sub-steps:

```elixir
{nested, result} =
  Tracer.Nesting.traced_map(clauses, fn clause ->
    Tracer.new(clause, input, evaluate(clause, input))
  end)

Tracer.new(operator, input, result, nested)
```

## License

MIT — see [LICENSE](LICENSE).
