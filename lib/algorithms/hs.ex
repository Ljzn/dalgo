defmodule HS do
  @moduledoc """
  Hirshberg Sinclair algorithm.
  """
  use Ring.Builder

  ## -----------------------------------------------------------------
  ## START
  ## -----------------------------------------------------------------

  start n do
    %{ring: nil, own: n, status: :idle, send: [], phase: 0}
  end

  ## -----------------------------------------------------------------
  ## MSGS
  ## -----------------------------------------------------------------

  msgs %{status: :chosen, own: own} do
    done own
  end


  msgs %{status: :defeated} do
    nil
  end


  msgs %{status: :idle, ring: ring, phase: phase}=s do
    distance = trunc(:math.pow(2, phase))
    message = %{
      notation: nil,
      value: s.own,
      origin: distance,
      distance: distance-1,
      type: :init,
    }

    send self(), :waiting
    send_msg ring, %{message | notation: :prev}
    send_msg ring, %{message | notation: :next}
  end

  msgs _ do
    nil
  end


  ## -----------------------------------------------------------------
  ## TRANS
  ## -----------------------------------------------------------------

  trans [
    msg: :waiting,
    state: s,
    do: %{s|status: :waiting}
  ]

  trans [
    msg: %{type: :stop, distance: n, origin: n},
    state: s,
    do: %{s|status: :defeated}
  ]

  trans [
    msg: %{type: :stop, distance: d}=m,
    state: s,
    do: (
      m1 = %{m|distance: d + 1}
      prepare_send s, m1
    )
  ]

  trans [
    msg: %{type: :ok, distance: n, origin: n},
    state: s,
    do: (
      case s.status do
        :waiting -> %{s|phase: s.phase + 1, status: :idle}
        _ -> s
      end
    )
  ]

  trans [
    msg: %{type: :ok, distance: d}=m,
    state: s,
    do: (
      m1 = %{m|distance: d + 1}
      prepare_send s, m1
    )
  ]

  trans [
    msg: %{type: :init, value: v, distance: d}=m,
    state: %{own: own}=s,
    do: (
      case compare(own, v) do
        :gt ->
          m1 = reverse %{m|type: :stop, distance: d + 1}
          prepare_send s, m1
        
        :lt ->
          m1 =
            if d == 0 do
              reverse %{m|type: :ok, distance: 1}
            else
              %{m|distance: d - 1}
            end
          %{s|status: :defeated} |> prepare_send(m1)
        
        :eq ->
          %{s|status: :chosen}
      end
    )
  ]


  ## -----------------------------------------------------------------
  ## private functions
  ## -----------------------------------------------------------------


  defp compare(a, b) do
    case a-b do
      0 -> :eq
      x when x>0 -> :gt
      _ -> :lt
    end
  end

end