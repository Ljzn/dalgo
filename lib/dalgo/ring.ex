defmodule Ring do

  alias Ring.Supervisor, as: RingSup
  alias Ring.Counter
  alias Ring.Manager
    
  def fit_ring(ring, pid) do
    {l1, l2} = Enum.split_while(ring, fn x -> x != pid end)
    l2 ++ l1
  end

  def next_node([_, node | _]), do: node

  def prev_node(ring), do: List.last(ring)

  def find_node(ring, distance \\ 1) do
    dist = rem distance, length(ring)
    Enum.at ring, dist
  end

  def start(node_mod, node_num) do
    Counter.reset()
    RingSup.start_link(node_mod)
    Manager.election(node_num)
  end


end