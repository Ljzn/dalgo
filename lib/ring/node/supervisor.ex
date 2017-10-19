defmodule Ring.Node.Supervisor do
  use Supervisor
  
  def start_link(node_mod) do
    Supervisor.start_link(__MODULE__, node_mod, name: __MODULE__)
  end

  def init(node_mod) do
    Supervisor.init([
      node_mod,
    ], strategy: :simple_one_for_one)
  end

end