defmodule Todo.DatabaseWorker do
  use GenServer

  defstruct [:db_folder]

  def start(db_folder) do
    GenServer.start(__MODULE__, db_folder)
  end

  def store(server, key, data) do
    GenServer.cast(server, {:store, key, data})
  end

  def get(server, key) do
    GenServer.call(server, {:get, key})
  end

  @impl GenServer
  def init(db_folder) do
    File.mkdir_p!(db_folder)
    {:ok, %Todo.DatabaseWorker{db_folder: db_folder}}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, database_worker = %{db_folder: db_folder}) do
    file_name(db_folder, key)
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, database_worker}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, database_worker) do
    data =
      case File.read(file_name(database_worker.db_folder, key)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    {:reply, data, database_worker}
  end

  defp file_name(db_folder, key) do
    Path.join(db_folder, to_string(key))
  end
end
