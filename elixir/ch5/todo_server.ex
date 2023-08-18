defmodule TodoServer do
  @spec start :: pid
  def start do
    spawn(fn -> loop(TodoList.new()) end)
  end

  @spec add_entry(TodoServer, TodoList.entry()) :: TodoServer
  def add_entry(todo_server, new_entry) do
    send(todo_server, {:add_entry, new_entry})
    todo_server
  end

  @spec entries(TodoServer, Date) :: TodoList.entries() | {:error, :timeout}
  def entries(todo_server, date) do
    send(todo_server, {:entries, self(), date})

    receive do
      {:todo_entries, entries} -> entries
    after
      5000 -> {:error, :timeout}
    end
  end

  @spec update_entry(TodoServer, TodoList.id(), TodoList.updater()) :: TodoServer
  def update_entry(todo_server, id, updater_fun) do
    send(todo_server, {:update_entry, id, updater_fun})
    todo_server
  end

  @spec delete_entry(TodoServer, TodoList.id()) :: TodoServer
  def delete_entry(todo_server, id) do
    send(todo_server, {:delete_entry, id})
    todo_server
  end

  @spec loop(TodoList) :: any
  defp loop(todo_list) do
    new_todo_list =
      receive do
        message ->
          process_message(todo_list, message)
      end

    loop(new_todo_list)
  end

  @spec process_message(TodoList, {:add_entry, TodoList.entry()}) :: TodoList
  defp process_message(todo_list, {:add_entry, new_entry}) do
    TodoList.add_entry(todo_list, new_entry)
  end

  @spec process_message(TodoList, {:entries, pid, Date}) :: TodoList
  defp process_message(todo_list, {:entries, caller, date}) do
    send(caller, {:todo_entries, TodoList.entries(todo_list, date)})
    todo_list
  end

  @spec process_message(TodoList, {:update_entry, TodoList.id(), TodoList.updater()}) :: TodoList
  defp process_message(todo_list, {:update_entry, id, updater_fun}) do
    TodoList.update_entry(todo_list, id, updater_fun)
  end

  @spec process_message(TodoList, {:delete_entry, TodoList.id()}) :: TodoList
  defp process_message(todo_list, {:delete_entry, id}) do
    TodoList.delete_entry(todo_list, id)
  end
end

defmodule TodoList do
  defstruct next_id: 1, entries: %{}

  @type id :: integer
  @type entry :: map
  @type entries :: %{id => entry}
  @type updater :: (entry -> entry)

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

  @spec update_entry(TodoList, id, updater) :: TodoList
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
