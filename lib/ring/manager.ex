defmodule Ring.Manager do
  @moduledoc """
  Manage the nodes. Start and stop nodes, count rounds and msgs. 
  """
  use GenServer
  alias Ring.Node.Supervisor, as: NodeSup
  @round_interval Application.get_env :dalgo, :round_interval

  ## -----------------------------------------------------------------
  ## API
  ## -----------------------------------------------------------------

  @doc """
  Start a number of nodes, then start election.
  """
  def election(n) do
    GenServer.cast __MODULE__, {:election, n}
  end

  @doc """
  Count the all messages passed.
  """
  def count_msg do
    GenServer.cast __MODULE__, :count_msg
  end

  def start_link(_) do
    GenServer.start_link __MODULE__, :ok, name: __MODULE__
  end

  ## -----------------------------------------------------------------
  ## CALLBACK
  ## -----------------------------------------------------------------

  def init(_) do
    {:ok, %{round: 0, ring: nil, msgs: 0}}
  end

  def handle_cast({:election, n}, s) do
    start_nodes(n)
    ring = get_ring()
    update_nodes_ring(ring)
    IO.inspect [ring, "election started"]
    send self(), :new_round
    {:noreply, %{s|ring: ring}}
  end

  def handle_cast(:count_msg, s) do
    {:noreply, %{s|msgs: s.msgs + 1}}
  end

  def handle_info(:new_round, %{ring: ring, round: round}=s) do
    new_round = round + 1
    for node <- ring do
      send node, :round_go
    end
    Process.send_after self(), :new_round, @round_interval

    {:noreply, %{s|round: new_round} }
  end

  def handle_info({:done, n}, %{round: round, msgs: msgs}) do
    IO.puts "[LEADER] #{n} [ROUND] #{round} [MESSAGE] #{msgs}"
    Supervisor.stop Ring.Supervisor
    {:noreply, :done}
  end

  def handle_info(_, :done), do: {:noreply, :done}

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
    # |> Enum.sort()
    # |> Enum.reverse() # worst case of LCR
  end

  defp update_nodes_ring(ring) do
    Enum.each(ring, fn pid ->
      send pid, {:ring, ring}
    end)
  end

end