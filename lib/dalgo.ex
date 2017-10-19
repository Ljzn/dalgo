defmodule Dalgo do
  @moduledoc """
  Documentation for Dalgo.
  """

  @doc """
  Start an ring algorithm with a number of nodes.

    LCR: Lelann, Chang-Roberts algorithm.
    HS: Hirshberg Sinclair algorithm.
  """
  def ring(algo, node) do
    Ring.start algo, node
  end
end
