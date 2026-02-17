# Tracer

Generic computation trace with visual tree rendering.

`Tracer` records what ran, what went in, what came out, and any
sub-steps — then renders the whole tree as a color-coded inspection output.

Extracted from the trace pattern in [Babel](https://github.com/alexocode/babel),
adapted for general use.

## Installation

```elixir
def deps do
  [
    {:tracer, "~> 0.1", github: "systemic-engineer/tracer"}
  ]
end
```

## Rendering

The `Inspect` implementation renders traces as a structured tree.
Colors are applied when the terminal supports them — green for `OK`, red for `ERROR`.

### Simple trace

```elixir
trace = Tracer.new(:double, 3, {:ok, 6})
Tracer.inspect(trace)
```

```
Tracer<OK> {
  data = 3

  :double
  |=> 6
}
```

### Nested trace — full tree (`depth: :infinity`)

```elixir
inner = Tracer.new(:validate_range, 42, {:ok, 42})
outer = Tracer.new(:parse_and_validate, "42", {:ok, 42}, [inner])
Tracer.inspect(outer, depth: :infinity)
```

```
Tracer<OK> {
  data = "42"

  :parse_and_validate
  |
  | :validate_range
  |  |=< 42
  |  |=> 42
  |
  |=> 42
}
```

### Error trace — only error branches (`depth: :error`)

```elixir
bad  = Tracer.new(:validate_range, -1, {:error, :out_of_range})
good = Tracer.new(:parse_int, "-1", {:ok, -1})
outer = Tracer.new(:parse_and_validate, "-1", {:error, [:out_of_range]}, [good, bad])
Tracer.inspect(outer, depth: :error)
```

```
Tracer<ERROR> {
  data = "-1"

  :parse_and_validate
  |
  | ... traces omitted (1) ...
  |
  | :validate_range
  |  |=< -1
  |  |=> {:error, :out_of_range}
  |
  |=> {:error, [:out_of_range]}
}
```

## API

```elixir
# Construct
Tracer.new(step, input, output)
Tracer.new(step, input, output, nested_traces)

# Status — ok? when output is not false/:error/{:error,_}
Tracer.ok?(trace)     # => boolean
Tracer.error?(trace)  # => boolean
Tracer.result(trace)  # => {:ok, value} | {:error, reason}

# Navigate the tree
Tracer.find(trace, &Tracer.error?/1)    # => [Tracer.t()]
Tracer.root_causes(trace)               # => [Tracer.t()] — leaf errors only
Tracer.reduce(trace, 0, fn _, n -> n + 1 end)  # => count of all traces

# Render
Tracer.inspect(trace)                         # top level only (default)
Tracer.inspect(trace, depth: :infinity)       # full tree
Tracer.inspect(trace, depth: :error)          # error branches only
Tracer.inspect(trace, depth: 2)               # up to 2 levels deep
inspect(trace, custom_options: [depth: 1])    # via standard Inspect opts
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

## Used By

- [Babel](https://github.com/alexocode/babel) — data transformation pipelines
  (the trace pattern originated here)
- [Brex](https://github.com/alexocode/brex) — composable business rules
  (planned: rule evaluation tree visualization)

## License

MIT — see [LICENSE](LICENSE).
