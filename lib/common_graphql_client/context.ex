defmodule CommonGraphQLClient.Context do
  @moduledoc false

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote location: :keep do
      def config do
        unquote(otp_app)
        |> Application.get_env(__MODULE__, [])
      end

      def config(key, default \\ fn -> nil end) do
        config()
        |> Keyword.get_lazy(key, default)
      end

      def client do
        config(:client, fn -> raise "Client Not Configured" end)
      end

      def list(term), do: client().list(term)
      def list!(term), do: client().list!(term)

      def list_by(term, variables), do: client().list_by(term, variables)
      def list_by!(term, variables), do: client().list_by!(term, variables)

      def get(term, id), do: client().get(term, id)
      def get!(term, id), do: client().get!(term, id)

      def get_by(term, variables), do: client().get_by(term, variables)
      def get_by!(term, variables), do: client().get_by!(term, variables)

      # @behaviour AbsintheWebSocket.Subscriber

      # @impl AbsintheWebSocket.Subscriber
      def subscribe do
      end

      defoverridable subscribe: 0
    end
  end
end
