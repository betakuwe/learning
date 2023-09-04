defmodule Todo.Database do
  use GenServer

  @db_folder "./persist"

  def start(num_workers \\ 3) do
    GenServer.start(__MODULE__, num_workers, name: __MODULE__)
  end

  def store(key, data) do
    GenServer.cast(__MODULE__, {:store, key, data})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @impl GenServer
  def init(num_workers) do
    db_workers =
      for i <- 0..(num_workers - 1), into: %{} do
        {:ok, db_worker} = Todo.DatabaseWorker.start(file_name(i))
        {i, db_worker}
      end

    {:ok, db_workers}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, db_workers) do
    choose_worker(db_workers, key)
    |> Todo.DatabaseWorker.store(key, data)

    {:noreply, db_workers}
  end

  @impl GenServer
  def handle_call({:get, key}, todo_server, db_workers) do
    choose_worker(db_workers, key)
    |> Todo.DatabaseWorker.get(todo_server, key)

    {:noreply, db_workers}
  end

  defp choose_worker(db_workers, key) do
    db_workers[:erlang.phash2(key, 3)]
  end

  defp file_name(key) do
    Path.join(@db_folder, to_string(key))
  end
end
