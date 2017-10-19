defmodule LCR do
  @moduledoc """
  Lelann, Chang-Roberts algorithm.
  """
  use GenServer
  alias Ring.Supervisor, as: RingSup
  alias Ring.Counter

  def child_spec(n) do
    %{
      id: {__MODULE__, n},
      start: {__MODULE__, :start_link, [n]},
      type: :worker,
    }
  end

  def start_link(_, n) do
    GenServer.start_link __MODULE__, n, []
  end

  def init(n) do
    state = %{ring: nil, own: n, send: n, status: :unknown}
    {:ok, state}
  end

  def handle_info({:ring, ring}, state) do
    new_ring = Ring.fit_ring(ring, self())
    {:noreply, %{state|ring: new_ring}}
  end

  def handle_info(:round_go, state) do
    if state.send do
      send Ring.next_node(state.ring), {:msg, state.send}
    end
    {:noreply, state}
  end

  def handle_info({:msg, m}, state) do
    Counter.add_one()
    new_state = handle(m, state)
    {:noreply, new_state}
  end

  defp handle(m, state) do
    state
    |> Map.put(:send, nil)
    |> status_change()
    |> compare_own_with_m(m)
  end

  defp status_change(%{status: :chosen}=s) do
    Counter.report()
    IO.puts "Node.#{s.own} has been chosen as leader."
    %{s|status: :reported}
  end
  defp status_change(s), do: s

  defp compare_own_with_m(%{own: own}=s, m) when m > own, do: %{s|send: m}
  defp compare_own_with_m(%{own: m}=s, m), do: %{s|status: :chosen, send: nil}
  defp compare_own_with_m(s, _), do: s
end