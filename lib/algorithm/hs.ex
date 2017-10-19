defmodule HS do
  @moduledoc """
  Hirshberg Sinclair algorithm.
  """
  use Ring.Algo

  ## -----------------------------------------------------------------
  ## START
  ## -----------------------------------------------------------------

  start n do
    %{ring: nil, own: n, phase: 0, status: :unknown}
  end

  ## -----------------------------------------------------------------
  ## MSGS
  ## -----------------------------------------------------------------

  msgs %{status: :chosen}=s do
    IO.puts "Node.#{s.own} has been chosen as leader."
    Counter.report()
    s
  end


  msgs %{status: :defeated}=s do
    s
  end


  msgs %{status: :unknown}=s do
    distance = trunc(:math.pow(2, s.phase))
      send Ring.next_node(s.ring), {:next, s.own, self(), distance}
      send Ring.prev_node(s.ring), {:prev, s.own, self(), distance}
    %{s|phase: s.phase + 1}
  end


  ## -----------------------------------------------------------------
  ## TRANS
  ## -----------------------------------------------------------------

  trans [
    msg: {_, _, _, _}=msg,
    state: s, 
    do: (
      Counter.add_one()
      compare(s, msg)
    )
  ]

  trans [
    msg: :stop,
    state: s,
    do: %{s|status: :defeated}
  ]

  trans [
    msg: :ok,
    state: s,
    do: s
  ]


  ## -----------------------------------------------------------------
  ## private functions
  ## -----------------------------------------------------------------

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