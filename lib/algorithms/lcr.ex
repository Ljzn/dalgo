defmodule LCR do
  @moduledoc """
  Lelann, Chang-Roberts algorithm.
  """
  use Ring.Builder

  ## -----------------------------------------------------------------
  ## START
  ## -----------------------------------------------------------------

  start n do
    %{own: n, send: [%{data: n}], status: :unknown}
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
    msg: %{data: m},
    state: s,
    do: (
      handle(m, s)
    )
  ]

  ## -----------------------------------------------------------------
  ## private functions
  ## -----------------------------------------------------------------

  defp handle(m, state) do
    state |> compare_own_with_m(m)
  end

  defp compare_own_with_m(%{own: own}=s, m) when m > own do
    prepare_send(s, %{data: m})
  end
  defp compare_own_with_m(%{own: m}=s, m) do
    %{s|status: :chosen}
  end
  defp compare_own_with_m(s, _), do: s
end