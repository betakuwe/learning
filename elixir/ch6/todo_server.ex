defmodule TodoServer do
  use GenServer

  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def add_entry(new_entry) do
    GenServer.cast(__MODULE__, {:add_entry, new_entry})
  end

  def entries(date) do
    GenServer.call(__MODULE__, {:entries, date})
  end

  def update_entry(id, updater_fun) do
    GenServer.cast(__MODULE__, {:update_entry, id, updater_fun})
  end

  def delete_entry(id) do
    GenServer.cast(__MODULE__, {:delete_entry, id})
  end

  @impl GenServer
  def init(_init_arg) do
    {:ok, TodoList.new()}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, todo_list) do
    {:reply, TodoList.entries(todo_list, date), todo_list}
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, todo_list) do
    {:noreply, TodoList.add_entry(todo_list, new_entry)}
  end

  @impl GenServer
  def handle_cast({:update_entry, id, updater_fun}, todo_list) do
    {:noreply, TodoList.update_entry(todo_list, id, updater_fun)}
  end

  @impl GenServer
  def handle_cast({:delete_entry, id}, todo_list) do
    {:noreply, TodoList.delete_entry(todo_list, id)}
  end

  @impl GenServer
  def handle_cast(_, todo_list) do
    {:stop, :unknown_request, todo_list}
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
    {_deleted_entry, new_todo_list} = pop_in(todo_list, [Access.key(:entries), id])
    new_todo_list
  end
end
