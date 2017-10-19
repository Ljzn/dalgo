defmodule Ring.Algo do
  @moduledoc """
  Ring Algorithm builder.

  In "Distributed Algorithm", each node in ring should
  has these attributes:
    start: init state
    msgs:  function that sending msgs at new round
    trans: function that changing state when receiving msg

  Can use `r!` to get current round number in msgs.
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

      def send_msg(ring, %{notation: :next}=m) do
        send Ring.next_node(ring), m
        # IO.inspect m
        Counter.add_one()
      end
      def send_msg(ring, %{notation: :prev}=m) do
        send Ring.prev_node(ring), m
        # IO.inspect m
        Counter.add_one()
      end

      def reverse(%{notation: :next}=m), do: %{m|notation: :prev}
      def reverse(%{notation: :prev}=m), do: %{m|notation: :next}

      defp send_all_msg(%{ring: ring, send: send}) when is_list(send) do
        send |> Enum.each(&send_msg(ring, &1))
      end
      defp send_all_msg(_), do: nil
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
      def handle_info({:round_go, var!(r!)}, s=unquote(state)) do
        var!(r!)
        send_all_msg(s)
        unquote(body)
        {:noreply, %{s| send: []} }
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