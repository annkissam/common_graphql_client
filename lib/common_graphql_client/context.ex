defmodule CommonGraphQLClient.Context do
  @moduledoc """
  """

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote location: :keep do
      @config fn ->
        unquote(otp_app) |> Application.get_env(__MODULE__, [])
      end
      @config_with_key fn key -> @config.() |> Keyword.get(key) end
      @client @config_with_key.(:client)

      defdelegate list(term), to: @client
      defdelegate list!(term), to: @client

      defdelegate list_by(term, variables), to: @client
      defdelegate list_by!(term, variables), to: @client

      defdelegate get(term, id), to: @client
      defdelegate get!(term, id), to: @client

      defdelegate get_by(term, variables), to: @client
      defdelegate get_by!(term, variables), to: @client

      # @behaviour AbsintheWebSocket.Subscriber

      # @impl AbsintheWebSocket.Subscriber
      def subscribe do
      end

      defoverridable [subscribe: 0]
    end
  end
end
