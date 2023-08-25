defmodule Todo.Server do
  use GenServer

  def start do
    GenServer.start(__MODULE__, nil)
  end

  def add_entry(server, new_entry) do
    GenServer.cast(server, {:add_entry, new_entry})
  end

  def entries(server, date) do
    GenServer.call(server, {:entries, date})
  end

  def update_entry(server, id, updater_fun) do
    GenServer.cast(server, {:update_entry, id, updater_fun})
  end

  def delete_entry(server, id) do
    GenServer.cast(server, {:delete_entry, id})
  end

  @impl GenServer
  def init(_init_arg) do
    {:ok, Todo.List.new()}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, todo_list) do
    {:reply, Todo.List.entries(todo_list, date), todo_list}
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, todo_list) do
    {:noreply, Todo.List.add_entry(todo_list, new_entry)}
  end

  @impl GenServer
  def handle_cast({:update_entry, id, updater_fun}, todo_list) do
    {:noreply, Todo.List.update_entry(todo_list, id, updater_fun)}
  end

  @impl GenServer
  def handle_cast({:delete_entry, id}, todo_list) do
    {:noreply, Todo.List.delete_entry(todo_list, id)}
  end

  @impl GenServer
  def handle_cast(_, todo_list) do
    {:stop, :unknown_request, todo_list}
  end
end
