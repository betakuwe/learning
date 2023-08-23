defmodule TodoList do
  defstruct next_id: 1, entries: %{}

  @type id :: integer
  @type entry :: map
  @type entries :: %{id => entry}

  @spec new([entry]) :: TodoList
  def new(entries \\ []) do
    for entry <- entries,
        reduce: %TodoList{} do
      todo_list_acc -> add_entry(todo_list_acc, entry)
    end
  end

  @spec add_entry(TodoList, entry) :: TodoList
  def add_entry(todo_list, entry) do
    entry_with_id = Map.put(entry, :id, todo_list.next_id)

    put_in(
      todo_list,
      [Access.key(:entries), todo_list.next_id],
      entry_with_id
    )
    |> update_in([Access.key(:next_id)], &(&1 + 1))
  end

  @spec entries(TodoList, Date) :: [entry]
  def entries(todo_list, date) do
    for {_id, entry} <- todo_list.entries,
        entry.date == date do
      entry
    end
  end

  @spec update_entry(TodoList, id, (entry -> entry)) :: TodoList
  def update_entry(todo_list, entry_id, updater_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        new_entry = updater_fun.(old_entry)
        put_in(todo_list, [Access.key(:entries), new_entry.id], new_entry)
    end
  end

  @spec delete_entry(TodoList, id) :: TodoList
  def delete_entry(todo_list, id) do
    {_deleted_entry, new_todo_list} = pop_in(todo_list, [Access.key(:entries), id])
    new_todo_list
  end
end

defmodule TodoList.CsvImporter do
  @spec import!(String) :: TodoList
  def import!(path) do
    for line <- File.stream!(path) do
      [date_string, title_string] =
        String.trim_trailing(line)
        |> String.split(",")

      %{date: Date.from_iso8601!(date_string), title: title_string}
    end
    |> TodoList.new()
  end
end

defimpl String.Chars, for: TodoList do
  def to_string(_) do
    "#TodoList"
  end
end

defimpl Collectable, for: TodoList do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(todo_list, {:cont, entry}) do
    TodoList.add_entry(todo_list, entry)
  end

  defp into_callback(todo_list, :done), do: todo_list
  defp into_callback(_todo_list, :halt), do: :ok
end
