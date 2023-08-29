defmodule Todo.List do
  defstruct next_id: 1, entries: %{}

  def new(entries \\ []) do
    for entry <- entries,
        reduce: %Todo.List{} do
      todo_list_acc -> add_entry(todo_list_acc, entry)
    end
  end

  def add_entry(todo_list, %{date: _date} = entry) do
    entry_with_id = Map.put(entry, :id, todo_list.next_id)

    put_in(
      todo_list,
      [Access.key(:entries), todo_list.next_id],
      entry_with_id
    )
    |> update_in([Access.key(:next_id)], &(&1 + 1))
  end

  def add_entry(todo_list, _) do
    todo_list
  end

  def entries(todo_list, date) do
    for {_id, entry} <- todo_list.entries,
        entry.date == date do
      entry
    end
  end

  def update_entry(todo_list, entry_id, updater_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        new_entry = updater_fun.(old_entry)
        put_in(todo_list, [Access.key(:entries), new_entry.id], new_entry)
    end
  end

  def delete_entry(todo_list, id) do
    {_deleted_entry, new_todo_list} = pop_in(todo_list, [Access.key(:entries), id])
    new_todo_list
  end
end
