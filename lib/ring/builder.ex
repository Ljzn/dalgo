defmodule Ring.Builder do
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
      import Ring.Builder
      alias Ring.Supervisor, as: RingSup
      alias Ring.Manager
    
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
        {:noreply, Map.put(state, :ring, new_ring)}
      end

      def send_msg(ring, %{to: :prev}=m) do
        send Ring.prev_node(ring), m
        # IO.inspect m
        Manager.count_msg()
      end
      def send_msg(ring, m) do
        send Ring.next_node(ring), m
        # IO.inspect m
        Manager.count_msg()
      end

      def reverse(%{to: :next}=m), do: %{m|to: :prev}
      def reverse(%{to: :prev}=m), do: %{m|to: :next}

      defp send_all_msg(%{ring: ring, send: send}) when is_list(send) do
        send |> Enum.each(&send_msg(ring, &1))
      end

      defp prepare_send(s, msg), do: %{s|send: [msg|s.send]}
      
      defp done(own), do: send Manager, {:done, own}
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
      def handle_info(:round_go, s=unquote(state)) do
        unquote(body)
        # IO.inspect s
        send_all_msg s
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