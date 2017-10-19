defmodule Ring.Manager do
  @moduledoc """
  Manage the nodes. Start and stop nodes, count rounds and msgs. 
  """
  use GenServer
  alias Ring.Node.Supervisor, as: NodeSup

  ## -----------------------------------------------------------------
  ## API
  ## -----------------------------------------------------------------

  @doc """
  Start a number of nodes, then start election.
  """
  def election(n) do
    GenServer.cast __MODULE__, {:election, n}
  end

  def start_link(_) do
    GenServer.start_link __MODULE__, :ok, name: __MODULE__
  end

  ## -----------------------------------------------------------------
  ## CALLBACK
  ## -----------------------------------------------------------------

  def init(_) do
    {:ok, %{round: 0, ring: nil}}
  end

  def handle_cast({:election, n}, s) do
    start_nodes(n)
    ring = get_ring()
    update_nodes_ring(ring)
    
    send self(), :new_round
    {:noreply, %{s|ring: ring}}
  end

  def handle_info(:new_round, %{ring: ring, round: round}) do
    new_round = round + 1
    IO.puts "[ROUND] #{new_round}"
    for node <- ring do
      send node, :round_go
    end
    Process.send_after self(), :new_round, 500

    {:noreply, %{ring: ring, round: new_round}}
  end

  def handle_info(:done, _) do
    Supervisor.stop(Ring.Supervisor)
    {:noreply, :done}
  end

  ## -----------------------------------------------------------------
  ## HELPER
  ## -----------------------------------------------------------------

  defp start_nodes(n) do
    for x <- 1..n do
      Supervisor.start_child(NodeSup, [x])
    end
  end

  defp get_ring do
    NodeSup
    |> Supervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} -> pid end)
    |> Enum.shuffle()
  end

  defp update_nodes_ring(ring) do
    Enum.each(ring, fn pid ->
      send pid, {:ring, ring}
    end)
  end

end