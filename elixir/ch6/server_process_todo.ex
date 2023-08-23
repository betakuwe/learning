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

  def add_entry(_, _) do
    {:error, :invalid_entry}
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

defmodule TodoServer do
  def init do
    TodoList.new()
  end

  def start do
    ServerProcess.start(TodoServer)
    |> Process.register(:server_pid)
  end

  def add_entry(new_entry) do
    ServerProcess.cast(:server_pid, {:add_entry, new_entry})
  end

  def entries(date) do
    ServerProcess.call(:server_pid, {:entries, date})
  end

  def update_entry(id, updater_fun) do
    ServerProcess.cast(:server_pid, {:update_entry, id, updater_fun})
  end

  def delete_entry(id) do
    ServerProcess.cast(:server_pid, {:delete_entry, id})
  end

  def handle_call({:entries, date}, todo_list) do
    {TodoList.entries(todo_list, date), todo_list}
  end

  def handle_cast({:add_entry, new_entry}, todo_list) do
    TodoList.add_entry(todo_list, new_entry)
  end

  def handle_cast({:update_entry, id, updater_fun}, todo_list) do
    TodoList.update_entry(todo_list, id, updater_fun)
  end

  def handle_cast({:delete_entry, id}, todo_list) do
    TodoList.delete_entry(todo_list, id)
  end

  def handle_cast(_, _) do
    {:error, :unknown_request}
  end
end

defmodule ServerProcess do
  @spec start(atom) :: pid
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init()
      loop(callback_module, initial_state)
    end)
  end

  @spec call(pid, any) :: any
  def call(server_pid, request) do
    send(server_pid, {:call, request, self()})

    receive do
      {:response, response} -> response
    after
      5000 -> {:error, :timeout}
    end
  end

  @spec cast(pid, any) :: {:cast, any}
  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end

  @spec loop(atom, any) :: any
  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} =
          callback_module.handle_call(request, current_state)

        send(caller, {:response, response})

        loop(callback_module, new_state)

      {:cast, request} ->
        new_state =
          callback_module.handle_cast(
            request,
            current_state
          )

        loop(callback_module, new_state)
    end
  end
end
