defmodule RecursionPractice do
  def list_len([]), do: 0
  def list_len([_ | tail]), do: 1 + list_len(tail)

  def range(from, to) when not is_integer(from) or not is_integer(to), do
    {:error, :non_integer_input}
  end

  def range(to, to), do: [to]
  def range(from, to) when from < to, do: [from | range(from + 1, to)]
  def range(from, to), do: [from | range(from - 1, to)]

  def positive([]), do: []
  def positive([head | tail]) when is_number(head) and head > 0, do: [head | positive(tail)]
  def positive([_ | tail]), do: positive(tail)
end
