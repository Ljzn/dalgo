defmodule HS do
  @moduledoc """
  Hirshberg Sinclair algorithm.
  """
  use Ring.Builder

  ## -----------------------------------------------------------------
  ## START
  ## -----------------------------------------------------------------

  start n do
    %{
      send: [],
      own: n, 
      phase: 0, 
      status: :unknown
    } |> prepare_new_phase_msgs()
  end

  ## -----------------------------------------------------------------
  ## MSGS
  ## -----------------------------------------------------------------

  msgs %{status: :chosen, own: own} do
    done own
  end

  msgs _ do
    nil
  end


  ## -----------------------------------------------------------------
  ## TRANS
  ## -----------------------------------------------------------------


  trans [
    msg: %{type: :stop, distance: n, origin: n },
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
    msg: %{type: :ok, distance: n, origin: n, phase: p},
    state: s,
    do: (
      case s.status do
        :unknown -> 
          if p == s.phase do
            %{s|phase: p + 1} |> prepare_new_phase_msgs()
          else
            s
          end
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

  defp prepare_new_phase_msgs(%{own: n, phase: phase}=s) do
    distance = trunc(:math.pow(2, phase))
    data = %{
      value: n,
      origin: distance,
      distance: distance-1,
      phase: phase,
      type: :init,
    }

    s
    |> prepare_send(Map.put(data, :to, :next))
    |> prepare_send(Map.put(data, :to, :prev))
  end

  defp compare(a, b) do
    case a-b do
      0 -> :eq
      x when x>0 -> :gt
      _ -> :lt
    end
  end

end