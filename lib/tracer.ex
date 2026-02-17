defmodule Tracer do
  @moduledoc """
  A generic computation trace with visual tree rendering.

  `Tracer` records the execution of a single step in a computation:
  what ran (`step`), what went in (`input`), what came out (`output`),
  and any sub-steps that were executed along the way (`nested`).

  The nested structure means a full computation tree can be represented
  as a single `Tracer` — inspectable as a color-coded tree.

  ## Inspect Options

  `Tracer`'s `Inspect` implementation accepts two custom options:

  - `depth` controls how many levels of nested traces to render (default `0`).
    * `non_neg_integer` — render nested traces up to this depth.
    * `:error` — omit passing nested traces; show only error branches.
    * `:infinity` — render the full tree.
  - `indent` controls the number of leading spaces (default `0`).

  Pass options via `inspect(trace, custom_options: [...])` or use
  `Tracer.inspect/2` as a shortcut.

  ## Examples

      iex> trace = Tracer.new(:double, 3, {:ok, 6})
      iex> Tracer.ok?(trace)
      true

      iex> trace = Tracer.new(:parse_int, "abc", {:error, :invalid})
      iex> Tracer.error?(trace)
      true
      iex> Tracer.result(trace)
      {:error, :invalid}
  """

  @type t() :: t(any(), any())
  @type t(output) :: t(any(), output)
  @type t(input, output) :: %__MODULE__{
          step: any(),
          input: input,
          output: output,
          nested: [t()]
        }

  defstruct step: nil, input: nil, output: nil, nested: []

  @doc """
  Builds a new `Tracer`.

  ## Examples

      iex> Tracer.new(:my_step, :input, {:ok, :output})
      %Tracer{step: :my_step, input: :input, output: {:ok, :output}, nested: []}

      iex> inner = Tracer.new(:inner, 1, {:ok, 2})
      iex> Tracer.new(:outer, 1, {:ok, 2}, [inner])
      %Tracer{step: :outer, input: 1, output: {:ok, 2}, nested: [%Tracer{step: :inner, input: 1, output: {:ok, 2}, nested: []}]}
  """
  @spec new(step :: any(), input :: any(), output :: any(), nested :: [t()]) :: t()
  def new(step, input, output, nested \\ []) do
    %__MODULE__{step: step, input: input, output: output, nested: nested}
  end

  @doc """
  Returns `true` if the trace output indicates an error.

  Error outputs: `false`, `:error`, `{:error, _}`.

  ## Examples

      iex> Tracer.error?(Tracer.new(:s, :i, {:error, :reason}))
      true

      iex> Tracer.error?(Tracer.new(:s, :i, false))
      true

      iex> Tracer.error?(Tracer.new(:s, :i, :error))
      true

      iex> Tracer.error?(Tracer.new(:s, :i, {:ok, :value}))
      false

      iex> Tracer.error?(Tracer.new(:s, :i, true))
      false
  """
  @spec error?(t()) :: boolean()
  def error?(%__MODULE__{output: output}), do: error_output?(output)

  defp error_output?(false), do: true
  defp error_output?(:error), do: true
  defp error_output?({:error, _}), do: true
  defp error_output?(_), do: false

  @doc """
  Returns `true` if the trace output does not indicate an error.

  ## Examples

      iex> Tracer.ok?(Tracer.new(:s, :i, {:ok, :value}))
      true

      iex> Tracer.ok?(Tracer.new(:s, :i, true))
      true

      iex> Tracer.ok?(Tracer.new(:s, :i, {:error, :reason}))
      false
  """
  @spec ok?(t()) :: boolean()
  def ok?(%__MODULE__{} = trace), do: not error?(trace)

  @doc """
  Normalizes the trace output to an `{:ok, value}` or `{:error, reason}` tuple.

  ## Examples

      iex> Tracer.result(Tracer.new(:s, :i, {:ok, 42}))
      {:ok, 42}

      iex> Tracer.result(Tracer.new(:s, :i, true))
      {:ok, true}

      iex> Tracer.result(Tracer.new(:s, :i, "raw value"))
      {:ok, "raw value"}

      iex> Tracer.result(Tracer.new(:s, :i, {:error, :bad}))
      {:error, :bad}

      iex> Tracer.result(Tracer.new(:s, :i, false))
      {:error, false}

      iex> Tracer.result(Tracer.new(:s, :i, :ok))
      {:ok, :ok}

      iex> Tracer.result(Tracer.new(:s, :i, :error))
      {:error, :unknown}
  """
  @spec result(t()) :: {:ok, any()} | {:error, any()}
  def result(%__MODULE__{output: output}) do
    case output do
      :error -> {:error, :unknown}
      {:error, reason} -> {:error, reason}
      false -> {:error, false}
      {:ok, value} -> {:ok, value}
      :ok -> {:ok, :ok}
      true -> {:ok, true}
      value -> {:ok, value}
    end
  end

  @doc """
  Returns the leaf error traces — the root causes of a failure.

  Recursively searches nested traces for traces that are erroring
  and have no nested traces of their own.

  ## Examples

      iex> leaf = Tracer.new(:validate, "x", false)
      iex> outer = Tracer.new(:pipeline, "x", {:error, :failed}, [leaf])
      iex> Tracer.root_causes(outer)
      [%Tracer{step: :validate, input: "x", output: false, nested: []}]
  """
  @spec root_causes(t()) :: [t()]
  def root_causes(%__MODULE__{} = trace) do
    find(trace, fn t -> error?(t) and t.nested == [] end)
  end

  @doc """
  Recursively searches the trace tree for traces matching a predicate.

  ## Examples

      iex> a = Tracer.new(:a, 1, {:ok, 2})
      iex> b = Tracer.new(:b, 2, {:error, :bad})
      iex> root = Tracer.new(:root, 1, {:error, :bad}, [a, b])
      iex> [r, e] = Tracer.find(root, &Tracer.error?/1)
      iex> r.step
      :root
      iex> e.step
      :b
  """
  @spec find(t(), (t() -> boolean())) :: [t()]
  def find(%__MODULE__{} = trace, fun) when is_function(fun, 1) do
    do_find(trace, fun)
  end

  defp do_find([], _fun), do: []
  defp do_find([t | rest], fun), do: do_find(t, fun) ++ do_find(rest, fun)

  defp do_find(%__MODULE__{} = trace, fun) do
    if fun.(trace) do
      [trace | do_find(trace.nested, fun)]
    else
      do_find(trace.nested, fun)
    end
  end

  @doc """
  Reduces over the trace and all its nested traces.

  ## Examples

      iex> a = Tracer.new(:a, 1, {:ok, 2})
      iex> b = Tracer.new(:b, 2, {:ok, 4})
      iex> root = Tracer.new(:root, 1, {:ok, 4}, [a, b])
      iex> Tracer.reduce(root, 0, fn _trace, count -> count + 1 end)
      3
  """
  @spec reduce(t(), accumulator, (t(), accumulator -> accumulator)) :: accumulator
        when accumulator: any()
  def reduce(%__MODULE__{} = trace, acc, fun) do
    Enum.reduce(trace.nested, fun.(trace, acc), &reduce(&1, &2, fun))
  end

  @type inspect_opts :: [
          depth: :error | :infinity | non_neg_integer(),
          indent: non_neg_integer()
        ]

  @doc """
  Shortcut for `inspect(trace, custom_options: opts)`.

  ## Options

  - `depth` — how many levels of nested traces to render (default `0`).
    * `non_neg_integer` — render nested traces up to this depth.
    * `:error` — only show error branches.
    * `:infinity` — render everything.
  - `indent` — number of leading spaces (default `0`).

  ## Examples

      iex> trace = Tracer.new(:my_step, 42, {:ok, 84})
      iex> output = Tracer.inspect(trace, syntax_colors: [])
      iex> output =~ "Tracer<OK>"
      true
  """
  @spec inspect(t(), inspect_opts()) :: String.t()
  def inspect(%__MODULE__{} = trace, opts \\ []) do
    Kernel.inspect(trace, custom_options: opts)
  end
end
