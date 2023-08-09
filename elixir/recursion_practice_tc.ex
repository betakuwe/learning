defmodule RecursionPracticeTC do
  def list_len(list), do: do_list_len(0, list)
  defp do_list_len(len, []), do: len
  defp do_list_len(len, [_ | tail]), do: do_list_len(len + 1, tail)

  def range(from, to) when not is_integer(from) or not is_integer(to) do
    {:error, :non_integer_input}
  end

  def range(from, to), do: do_range([], from, to)
  defp do_range(list, from, from), do: [from | list]
  defp do_range(list, from, to) when from < to, do: do_range([to | list], from, to - 1)
  defp do_range(list, from, to), do: do_range([to | list], from, to + 1)

  def positive(list), do: do_positive([], list)
  defp do_positive(list, []), do: list

  defp do_positive(list, [head | tail]) when is_number(head) and head > 0 do
    do_positive([head | list], tail)
  end

  defp do_positive(list, [_ | tail]), do: do_positive(list, tail)
end
