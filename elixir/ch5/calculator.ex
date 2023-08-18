defmodule Calculator do
  @spec start :: pid
  def start do
    spawn(fn -> loop(0) end)
  end

  @spec value(pid) :: number
  def value(server_pid) do
    send(server_pid, {:value, self()})

    receive do
      {:response, value} ->
        value
    end
  end

  @spec add(pid, number) :: {:add, number}
  def add(server_pid, value), do: send(server_pid, {:add, value})

  @spec sub(pid, number) :: {:sub, number}
  def sub(server_pid, value), do: send(server_pid, {:sub, value})

  @spec mul(pid, number) :: {:mul, number}
  def mul(server_pid, value), do: send(server_pid, {:mul, value})

  @spec div(pid, number) :: {:div, number}
  def div(server_pid, value), do: send(server_pid, {:div, value})

  @spec loop(number) :: any
  defp loop(current_value) do
    new_value =
      receive do
        message -> process_message(current_value, message)
      end

    loop(new_value)
  end

  @spec process_message(number, {:value, pid}) :: number
  defp process_message(current_value, {:value, caller}) do
    send(caller, {:response, current_value})
    current_value
  end

  @spec process_message(number, {:add, number}) :: number
  defp process_message(current_value, {:add, value}), do: current_value + value

  @spec process_message(number, {:sub, number}) :: number
  defp process_message(current_value, {:sub, value}), do: current_value - value

  @spec process_message(number, {:mul, number}) :: number
  defp process_message(current_value, {:mul, value}), do: current_value * value

  @spec process_message(number, {:div, number}) :: number
  defp process_message(current_value, {:div, value}), do: current_value / value

  @spec process_message(number, any) :: number
  defp process_message(current_value, invalid_request) do
    IO.puts("invalid request #{inspect(invalid_request)}")
    current_value
  end
end
