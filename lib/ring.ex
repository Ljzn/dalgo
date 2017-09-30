defmodule Ring do

  alias Ring.Supervisor, as: RingSup
  alias Ring.Counter
    
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
    {:ok, sup} = RingSup.start_link(node_mod)
    for x <- 1..node_num do
      Supervisor.start_child(sup, [x])
    end

    sup
    |> get_ring()
    |> update_node_ring()
    |> start_leader_election()
  end

  defp get_ring(sup) do
    sup
    |> Supervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} -> pid end)
    |> Enum.shuffle()
  end

  defp update_node_ring(ring) do
    Enum.each(ring, fn pid ->
      send pid, {:ring, ring}
    end)
    IO.inspect ring
  end

  defp start_leader_election(ring) do
    Process.register self(), __MODULE__
    task = Task.async(&print_round/0)
    :timer.sleep 100
    Enum.each(ring, fn pid ->
      :timer.send_interval 1000, pid, :round_go
    end)

    receive do
      :done ->
        Task.shutdown task
        Process.unregister __MODULE__
    end
  end

  defp print_round do
    for x <- 1..100 do
      :timer.sleep 1000
      IO.puts "round #{x}"
    end
  end

end