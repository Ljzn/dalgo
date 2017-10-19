defmodule Ring.Counter do
  use Agent

  def reset do
    case start_link() do
      {:error, _} ->
        Agent.cast __MODULE__, fn _ -> 0 end
      _ -> :ok
    end
  end

  def add_one do
    Agent.cast __MODULE__, fn x -> x + 1 end
  end

  def start_link do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def report do
    send Ring.Manager, :done
    n = Agent.get __MODULE__, fn x -> x end
    IO.puts "#{n} messages have been Communicated."    
    Supervisor.stop Ring.Supervisor
    Agent.stop __MODULE__
  end

end