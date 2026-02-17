# coveralls-ignore-start
defmodule Tracer.Inspect do
  @moduledoc false

  # Strips line-break IR nodes from an Inspect.Algebra document.
  # Used to render nested trace lines compactly (no multi-line breaks).
  @doc false
  def no_breaks(doc) do
    case doc do
      {:doc_break, "", _mode} ->
        :doc_nil

      {:doc_break, break, _mode} ->
        break

      {:doc_cons, left, right} ->
        {:doc_cons, no_breaks(left), no_breaks(right)}

      {:doc_nest, doc, indent, mode} ->
        {:doc_nest, no_breaks(doc), indent, mode}

      {type, doc, mode} when type in [:doc_group, :doc_fits] ->
        {type, no_breaks(doc), mode}

      {:doc_fits, doc} ->
        {:doc_fits, no_breaks(doc)}

      {:doc_color, doc, color} ->
        {:doc_color, no_breaks(doc), color}

      other ->
        other
    end
  end
end

# coveralls-ignore-stop

defimpl Inspect, for: Tracer do
  import Inspect.Algebra
  import Tracer.Inspect, only: [no_breaks: 1]

  @doc """
  Renders a `Tracer` as a color-coded tree.

  ## Inspect Options

  Two custom options are supported (via `custom_options`):

  - `depth` — controls nested trace rendering (default `0`):
    * `0` — top level only; nested traces are summarized as "omitted (N)".
    * positive integer — render this many levels deep.
    * `:error` — only render error branches; omit passing sub-traces.
    * `:infinity` — render the complete tree.
  - `indent` — leading spaces (default `0`). Used internally for nesting.

  ## Examples

      iex> trace = Tracer.new(:double, 3, {:ok, 6})
      iex> output = inspect(trace, custom_options: [depth: :infinity], syntax_colors: [])
      iex> output =~ "Tracer<OK>"
      true
      iex> output =~ "data = 3"
      true
      iex> output =~ "|=> 6"
      true

      iex> trace = Tracer.new(:parse, "abc", {:error, :invalid})
      iex> output = inspect(trace, custom_options: [], syntax_colors: [])
      iex> output =~ "Tracer<ERROR>"
      true

      iex> inner = Tracer.new(:validate, -1, {:error, :out_of_range})
      iex> outer = Tracer.new(:pipeline, -1, {:error, [:validate]}, [inner])
      iex> output = inspect(outer, custom_options: [depth: :error], syntax_colors: [])
      iex> output =~ "| :validate"
      true
      iex> output =~ "|=< -1"
      true
      iex> output =~ "|=> {:error, :out_of_range}"
      true

      iex> ok_inner = Tracer.new(:step_a, 1, {:ok, 2})
      iex> outer = Tracer.new(:pipeline, 1, {:ok, 2}, [ok_inner])
      iex> output = inspect(outer, custom_options: [depth: :infinity], syntax_colors: [])
      iex> output =~ "| :step_a"
      true
      iex> output =~ "|=> 2"
      true

      iex> inner = Tracer.new(:inner, 1, {:ok, 2})
      iex> outer = Tracer.new(:outer, 1, {:ok, 2}, [inner])
      iex> output = inspect(outer, custom_options: [depth: 1], syntax_colors: [])
      iex> output =~ "| :inner"
      true

      iex> inner = Tracer.new(:inner, 1, {:ok, 2})
      iex> outer = Tracer.new(:outer, 1, {:ok, 2}, [inner])
      iex> output = inspect(outer, custom_options: [depth: 0], syntax_colors: [])
      iex> output =~ "traces omitted (1)"
      true

      iex> trace = Tracer.new(:step, 1, {:ok, 2})
      iex> output = inspect(trace, custom_options: [indent: 2], syntax_colors: [])
      iex> String.starts_with?(output, "  ")
      true
  """
  def inspect(%Tracer{} = trace, opts) do
    opts = merge_default_opts(opts)
    level = opts.custom_options[:indent]

    nest(
      concat([
        nesting(level),
        header(trace, opts),
        color("{", :operator, opts),
        nest(properties(trace, opts), 2),
        line(),
        color("}", :operator, opts)
      ]),
      level
    )
  end

  @default_opts [indent: 0, depth: 0]

  defp merge_default_opts(%Inspect.Opts{} = opts) do
    update_in(opts.custom_options, &Keyword.merge(@default_opts, &1))
  end

  defp nesting(level, indent \\ [])
  defp nesting(0, indent), do: concat(indent)
  defp nesting(level, indent) when level > 0, do: nesting(level - 1, [" " | indent])

  defp header(trace, opts) do
    {status, status_color} =
      if Tracer.ok?(trace) do
        {"OK", :green}
      else
        {"ERROR", :red}
      end

    group(
      concat([
        color("Tracer", :atom, opts),
        color("<", :operator, opts),
        force_color(status, status_color, opts),
        color(">", :operator, opts),
        " "
      ])
    )
  end

  # No syntax_colors means the output doesn't support colors — render plain.
  defp force_color(doc, _color, %{syntax_colors: []}), do: doc

  # coveralls-ignore-start
  defp force_color(doc, color, %{syntax_colors: syntax_colors}) do
    postcolor = Keyword.get(syntax_colors, :reset, :reset)
    concat([{:doc_color, doc, color}, {:doc_color, :doc_nil, postcolor}])
  end

  # coveralls-ignore-stop

  defp properties(trace, opts) do
    concat([
      line(),
      data(trace, opts),
      line(),
      line(),
      step(trace, opts),
      line(),
      nested(trace, opts),
      output(trace, opts)
    ])
  end

  defp data(%{input: input}, opts) do
    group(
      nest(
        flex_glue(
          concat([color("data", :variable, opts), " ", color("=", :operator, opts)]),
          to_doc(input, opts)
        ),
        2
      )
    )
  end

  defp step(%Tracer{step: step}, opts), do: to_doc(step, opts)

  defp nested(%{nested: []}, _opts), do: empty()

  defp nested(%{nested: nested}, opts) do
    nested
    |> lines_for_nested(opts)
    |> Enum.flat_map(&[&1, line()])
    |> concat()
    |> group()
  end

  defp lines_for_nested([], _opts), do: []

  defp lines_for_nested(traces, opts) when is_list(traces) do
    {depth, opts} = decrement_depth(opts)
    {traces, nr_of_omitted} = omit_traces_by_depth(traces, depth)

    traces
    |> Enum.map(fn trace ->
      [
        no_breaks(step(trace, opts)),
        inline_input(trace, opts),
        lines_for_nested(trace.nested, opts),
        inline_output(trace, opts),
        ""
      ]
    end)
    |> List.flatten()
    |> List.insert_at(0, "")
    |> summarize_omissions(nr_of_omitted)
    |> Enum.map(&concat("| ", &1))
  end

  defp decrement_depth(opts) do
    depth = opts.custom_options[:depth]

    {
      depth,
      case depth do
        :error -> opts
        :infinity -> opts
        d when is_integer(d) -> put_in(opts.custom_options[:depth], max(d - 1, 0))
      end
    }
  end

  defp omit_traces_by_depth(traces, :error) do
    {error_traces, nr_of_omitted} =
      Enum.reduce(traces, {[], 0}, fn trace, {errors, n} ->
        if Tracer.error?(trace) do
          {[trace | errors], n}
        else
          {errors, n + deep_count(trace)}
        end
      end)

    {Enum.reverse(error_traces), nr_of_omitted}
  end

  defp omit_traces_by_depth(traces, :infinity), do: {traces, 0}
  defp omit_traces_by_depth(traces, depth) when depth > 0, do: {traces, 0}
  defp omit_traces_by_depth(traces, 0), do: {[], deep_count(traces)}

  defp deep_count(traces) when is_list(traces) do
    Enum.reduce(traces, 0, &(deep_count(&1) + &2))
  end

  defp deep_count(%Tracer{} = trace) do
    Tracer.reduce(trace, 0, fn _, c -> c + 1 end)
  end

  defp inline_input(%{input: input}, opts) do
    no_breaks(concat([" |=< ", to_doc(input, %{opts | limit: 5})]))
  end

  defp inline_output(%Tracer{} = trace, opts) do
    trace
    |> Tracer.result()
    |> inline_output(opts)
  end

  defp inline_output(output, opts) do
    value =
      case output do
        {:ok, v} -> v
        {:error, reason} -> {:error, reason}
      end

    no_breaks(concat([" |=> ", to_doc(value, %{opts | limit: 5})]))
  end

  defp output(%Tracer{} = trace, opts) do
    trace
    |> Tracer.result()
    |> output(opts)
  end

  defp output(output, opts) do
    value =
      case output do
        {:ok, v} -> v
        {:error, reason} -> {:error, reason}
      end

    no_breaks(concat(["|=> ", to_doc(value, opts)]))
  end

  defp summarize_omissions(lines, 0), do: lines
  defp summarize_omissions(lines, n), do: ["", "... traces omitted (#{n}) ..." | lines]
end
