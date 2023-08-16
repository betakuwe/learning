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
    pop_in(todo_list, [Access.key(:entries), id])
  end
end

defmodule TodoList.CsvImporter do
  @spec import!(String) :: TodoList
  def import!(path) do
    for line <- File.stream!(path) do
      String.trim_trailing(line)
      |> String.split(",")
      |> (fn [date_string, title_string] ->
            %{date: Date.from_iso8601!(date_string), title: title_string}
          end).()
    end
    |> TodoList.new()
  end
end
