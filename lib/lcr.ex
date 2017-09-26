defmodule LCR do
  @moduledoc """
  Lelann, Chang-Roberts algorithm.
  """
  alias LCR.Supervisor, as: LCRSup

  def start(node_num) do
    {:ok, sup} = LCRSup.start_link()
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
  end

  defp update_node_ring(ring) do
    Enum.each(ring, fn pid ->
      send pid, {:ring, ring}
    end)
    IO.inspect ring
  end

  defp start_leader_election(ring) do
    spawn_link(&print_round/0)
    :timer.sleep 100
    Enum.each(ring, fn pid ->
      :timer.send_interval 1000, pid, :round_go
    end)
  end

  defp print_round do
    for x <- 1..100 do
      :timer.sleep 1000
      IO.puts "round #{x}"
    end
  end

end