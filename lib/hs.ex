defmodule HS do
  @moduledoc """
  Hirshberg Sinclair algorithm.
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
    state = %{ring: nil, own: n, phase: 0, status: :unknown}
    {:ok, state}
  end

  def handle_info({:ring, ring}, state) do
    new_ring = Ring.fit_ring(ring, self())
    {:noreply, %{state|ring: new_ring}}
  end

  def handle_info(:round_go, %{status: :chosen}=s) do
    IO.puts "Node.#{s.own} has been chosen as leader."
    Counter.report()
    {:noreply, s}
  end
  def handle_info(:round_go, %{status: :defeated}=s) do
    {:noreply, s}
  end
  def handle_info(:round_go, %{status: :unknown}=s) do
    distance = trunc(:math.pow(2, s.phase))
      send Ring.next_node(s.ring), {:next, s.own, self(), distance}
      send Ring.prev_node(s.ring), {:prev, s.own, self(), distance}
    {:noreply, %{s|phase: s.phase + 1}}
  end

  def handle_info({direction, _, _, _}=msg, s) when direction in [:next, :prev] do
    Counter.add_one()
    new_state = compare(s, msg)
    {:noreply, new_state}
  end

  def handle_info(:stop, s) do
    {:noreply, %{s|status: :defeated}}
  end

  def handle_info(:ok, s) do
    {:noreply, s}
  end

  defp compare(%{own: own}=s, {_d, v, pid, 0}) when v > own do
    send pid, :ok
    %{s|status: :defeated}
  end
  defp compare(%{own: own}=s, {d, v, pid, distance}) when v > own do
    case d do
      :next ->
        send Ring.next_node(s.ring), {:next, v, pid, distance-1}
      :prev ->
        send Ring.prev_node(s.ring), {:prev, v, pid, distance-1}
    end
    %{s|status: :defeated}
  end
  defp compare(%{own: own}=s, {_, v, pid, _}) when v < own do
    send pid, :stop
    s
  end
  defp compare(%{own: own}=s, {_, own, _, _}) do
    %{s|status: :chosen}
  end
end