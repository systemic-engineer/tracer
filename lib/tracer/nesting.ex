defmodule Tracer.Nesting do
  @moduledoc """
  Utilities for collecting `Tracer` structs while running computations.

  When a step executes sub-steps (e.g. an operator evaluating its clauses),
  you need to accumulate both the sub-traces and the combined result.
  These functions handle that bookkeeping.

  ## Usage pattern

      def evaluate(operator, input) do
        {nested, result} =
          Tracer.Nesting.traced_map(operator.clauses, fn clause ->
            Tracer.new(clause, input, apply_clause(clause, input))
          end)

        Tracer.new(operator, input, result, nested)
      end
  """

  alias Tracer

  @type result(output) :: {:ok, output} | {:error, any()}
  @type traces_with_result(output) :: {[Tracer.t()], result(output)}

  @doc """
  Maps over an enumerable, collecting both traces and a combined result.

  Each call to `mapper` must return a `Tracer`. Results are accumulated:
  all `:ok` → `{:ok, [values]}`, any `:error` → `{:error, [reasons]}`.

  ## Examples

      iex> steps = [:double, :negate]
      iex> {traces, result} =
      ...>   Tracer.Nesting.traced_map(steps, fn step ->
      ...>     Tracer.new(step, 4, {:ok, 4 * 2})
      ...>   end)
      iex> result
      {:ok, [8, 8]}
      iex> length(traces)
      2

      iex> steps = [:ok_step, :bad_step]
      iex> {_traces, result} =
      ...>   Tracer.Nesting.traced_map(steps, fn
      ...>     :ok_step  -> Tracer.new(:ok_step, 1, {:ok, 2})
      ...>     :bad_step -> Tracer.new(:bad_step, 1, {:error, :fail})
      ...>   end)
      iex> result
      {:error, [:fail]}
  """
  @spec traced_map(Enumerable.t(input), (input -> Tracer.t(output))) ::
          {[Tracer.t()], result([output])}
        when input: any(), output: any()
  def traced_map(enum, mapper) when is_function(mapper, 1) do
    traced_reduce_while(enum, mapper, {:ok, []}, fn result, accumulated ->
      {:cont, collect_results(result, accumulated)}
    end)
  end

  @doc """
  Like `traced_map/2` but supports early termination via `{:halt, acc}`.

  The `accumulator` function returns `{:cont, acc}` to continue or
  `{:halt, acc}` to stop iteration. The `finalize` function is applied
  to the accumulated value before returning (default: reverse list results).

  ## Examples

      iex> steps = [1, 2, 3, 4, 5]
      iex> {traces, result} =
      ...>   Tracer.Nesting.traced_reduce_while(
      ...>     steps,
      ...>     fn n -> Tracer.new(n, n, {:ok, n * 2}) end,
      ...>     {:ok, []},
      ...>     fn {:ok, v}, {:ok, acc} -> {:cont, {:ok, [v | acc]}} end
      ...>   )
      iex> result
      {:ok, [2, 4, 6, 8, 10]}
      iex> length(traces)
      5

      iex> # Mapper returning {[traces], result} tuple instead of a single Tracer
      iex> {traces, result} =
      ...>   Tracer.Nesting.traced_reduce_while(
      ...>     [:a],
      ...>     fn :a ->
      ...>       sub = Tracer.new(:sub, :a, {:ok, 1})
      ...>       {[sub], {:ok, 1}}
      ...>     end,
      ...>     {:ok, []},
      ...>     fn {:ok, v}, {:ok, acc} -> {:cont, {:ok, [v | acc]}} end
      ...>   )
      iex> result
      {:ok, [1]}
      iex> length(traces)
      1
  """
  @spec traced_reduce_while(
          enum :: Enumerable.t(input),
          mapper :: (input -> Tracer.t(output) | traces_with_result(output)),
          begin :: accumulated,
          accumulator :: (result(output), accumulated -> {:cont | :halt, accumulated}),
          finalize :: (accumulated -> accumulated)
        ) :: {[Tracer.t()], accumulated}
        when input: any(), output: any(), accumulated: any()
  def traced_reduce_while(enum, mapper, begin_acc, accumulator, finalize \\ &reverse_results/1)
      when is_function(mapper, 1)
      when is_function(accumulator, 2) do
    {traces, accumulated} =
      Enum.reduce_while(enum, {[], begin_acc}, fn element, {traces, acc} ->
        {nested_traces, result} =
          case mapper.(element) do
            %Tracer{} = trace -> {[trace], Tracer.result(trace)}
            {ts, r} -> {ts, r}
          end

        {cont_or_halt, acc} = accumulator.(result, acc)
        {cont_or_halt, {Enum.reverse(nested_traces) ++ traces, acc}}
      end)

    {Enum.reverse(traces), finalize.(accumulated)}
  end

  @doc """
  Combines `collect_oks/2` and `collect_errors/2`.

  When the result is `:ok` and the accumulated state is `{:ok, _}`, appends
  to the ok list. Otherwise switches to or extends the error list.

  ## Examples

      iex> Tracer.Nesting.collect_results({:ok, 1}, {:ok, []})
      {:ok, [1]}

      iex> Tracer.Nesting.collect_results({:error, :bad}, {:ok, [1]})
      {:error, [:bad]}

      iex> Tracer.Nesting.collect_results({:ok, 2}, {:error, [:bad]})
      {:error, [:bad]}

      iex> Tracer.Nesting.collect_results({:error, :also}, {:error, [:bad]})
      {:error, [:also, :bad]}
  """
  @spec collect_results(result(any()), result([any()])) :: result([any()])
  def collect_results(result, collected) do
    collect_oks(result, collected) || collect_errors(result, collected)
  end

  @doc """
  Aggregates `:ok` results. Returns `nil` for any `:error` input or state.

  ## Examples

      iex> Tracer.Nesting.collect_oks({:ok, :a}, {:ok, []})
      {:ok, [:a]}

      iex> Tracer.Nesting.collect_oks({:ok, :b}, {:ok, [:a]})
      {:ok, [:b, :a]}

      iex> Tracer.Nesting.collect_oks({:error, :bad}, {:ok, [:a]})
      nil

      iex> Tracer.Nesting.collect_oks({:ok, :a}, {:error, [:bad]})
      nil
  """
  @spec collect_oks({:ok, value}, {:ok, [value]}) :: {:ok, [value]} when value: any()
  @spec collect_oks({:error, any()}, {:ok, any()}) :: nil
  @spec collect_oks(result(any()), {:error, any()}) :: nil
  def collect_oks(result, {:ok, list}) do
    case result do
      {:ok, value} -> {:ok, [value | list]}
      {:error, _} -> nil
    end
  end

  def collect_oks(_result, {:error, _}), do: nil

  @doc """
  Aggregates `:error` results. Ignores `:ok` results when already in error state.

  ## Examples

      iex> Tracer.Nesting.collect_errors({:error, :bad}, {:ok, [:a]})
      {:error, [:bad]}

      iex> Tracer.Nesting.collect_errors({:error, :also}, {:error, [:bad]})
      {:error, [:also, :bad]}

      iex> Tracer.Nesting.collect_errors({:error, [:x, :y]}, {:error, [:bad]})
      {:error, [:y, :x, :bad]}

      iex> Tracer.Nesting.collect_errors({:ok, :a}, {:ok, [:b]})
      nil
  """
  @spec collect_errors({:ok, any()}, {:ok, any()}) :: nil
  @spec collect_errors({:error, reason}, {:ok, any()}) :: {:error, [reason]} when reason: any()
  @spec collect_errors({:error, [reason]}, {:error, [reason]}) :: {:error, [reason]}
        when reason: any()
  def collect_errors(result, {:ok, _}) do
    case result do
      {:ok, _} -> nil
      {:error, reason} -> {:error, List.wrap(reason)}
    end
  end

  def collect_errors(result, {:error, list}) do
    case result do
      {:ok, _} -> {:error, list}
      {:error, reasons} when is_list(reasons) -> {:error, Enum.reverse(reasons) ++ list}
      {:error, reason} -> {:error, [reason | list]}
    end
  end

  @doc """
  Reverses a list inside a result tuple. Default finalize step for `traced_reduce_while/5`.

  ## Examples

      iex> Tracer.Nesting.reverse_results({:ok, [3, 2, 1]})
      {:ok, [1, 2, 3]}

      iex> Tracer.Nesting.reverse_results({:error, [:c, :b, :a]})
      {:error, [:a, :b, :c]}

      iex> Tracer.Nesting.reverse_results({:ok, :not_a_list})
      {:ok, :not_a_list}
  """
  @spec reverse_results(result([any()])) :: result([any()])
  @spec reverse_results(result(any())) :: result(any())
  def reverse_results({ok_or_error, list}) when is_list(list) do
    {ok_or_error, Enum.reverse(list)}
  end

  def reverse_results(other), do: other
end
