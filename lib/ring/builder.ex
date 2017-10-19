defmodule Ring.Algo do
  @moduledoc """
  Ring Algorithm builder.

  In "Distributed Algorithm", each node in ring should
  has these attributes:
    start: init state
    msgs:  function that sending msgs at new round
    trans: function that changing state when receiving msg
  """
  defmacro __using__(_) do
    quote do
      use GenServer
      import Ring.Algo
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

      def handle_info({:ring, ring}, state) do
        new_ring = Ring.fit_ring(ring, self())
        {:noreply, %{state|ring: new_ring}}
      end

    end
  end

  defmacro start(arg, [do: body]) do
    quote do
      def init(unquote(arg)) do
        {:ok, unquote(body)}
      end
    end
  end

  defmacro msgs(state, [do: body]) do
    quote do
      def handle_info(:round_go, unquote(state)) do
        {:noreply, unquote(body)}
      end
    end
  end

  defmacro trans([msg: msg, state: state, do: body]) do
    quote do
      def handle_info(unquote(msg), unquote(state)) do
        {:noreply, unquote(body)}
      end
    end
  end

end