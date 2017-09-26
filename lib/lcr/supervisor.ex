defmodule LCR.Supervisor do
  use Supervisor
  
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Supervisor.init([
      LCR.Node,
    ], strategy: :simple_one_for_one)
  end

end