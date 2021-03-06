defmodule Ring.Supervisor do
  use Supervisor
  alias Ring.Node.Supervisor, as: NodeSup
  alias Ring.Manager
  
  def start_link(node_mod) do
    Supervisor.start_link(__MODULE__, node_mod, name: __MODULE__)
  end

  def init(node_mod) do
    Supervisor.init([
      {NodeSup, node_mod},
      Manager,
    ], strategy: :one_for_one)
  end

end