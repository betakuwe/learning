defmodule EchoServer do
  use GenServer

  @impl GenServer
  def handle_call(some_request, _from, server_state) do
    {:reply, some_request, server_state}
  end
end
