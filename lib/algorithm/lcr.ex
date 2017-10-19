defmodule LCR do
  @moduledoc """
  Lelann, Chang-Roberts algorithm.
  """
  use Ring.Algo

  ## -----------------------------------------------------------------
  ## START
  ## -----------------------------------------------------------------

  start n do
    %{ring: nil, own: n, send: n, status: :unknown}
  end

  ## -----------------------------------------------------------------
  ## MSGS
  ## -----------------------------------------------------------------

  msgs %{send: nil} do
    nil
  end

  msgs %{send: send, ring: ring} do
    send Ring.next_node(ring), {:msg, send}
    Counter.add_one()
  end

  ## -----------------------------------------------------------------
  ## TRANS
  ## -----------------------------------------------------------------

  trans [
    msg: {:msg, m},
    state: s,
    do: (
      handle(m, s)
    )
  ]

  ## -----------------------------------------------------------------
  ## private functions
  ## -----------------------------------------------------------------

  defp handle(m, state) do
    state
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