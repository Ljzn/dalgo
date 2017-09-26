defmodule Ring do
    
  def fit_ring(ring, pid) do
    {l1, l2} = Enum.split_while(ring, fn x -> x != pid end)
    l2 ++ l1
  end

  def next_node([_, node | _]), do: node

  def distance_node(ring, distance \\ 1) do
    dist = rem distance, length(ring)
    Enum.at ring, dist
  end

end