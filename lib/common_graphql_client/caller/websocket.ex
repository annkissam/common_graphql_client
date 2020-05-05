if Code.ensure_loaded?(AbsintheWebSocket) do
  defmodule CommonGraphQLClient.Caller.WebSocket do
    @moduledoc false

    @behaviour CommonGraphQLClient.CallerBehaviour

    @impl CommonGraphQLClient.CallerBehaviour
    def post(client, query, variables \\ [], opts \\ []) do
      query_server_name = Module.concat([client.mod(), Caller, QueryServer])

      AbsintheWebSocket.QueryServer.post(query_server_name, query, variables, opts)
    end

    @impl CommonGraphQLClient.CallerBehaviour
    def subscribe(client, subscription_name, callback, query, variables \\ []) do
      subscription_server_name = Module.concat([client.mod(), Caller, SubscriptionServer])

      AbsintheWebSocket.SubscriptionServer.subscribe(
        subscription_server_name,
        subscription_name,
        callback,
        query,
        variables
      )
    end

    @impl CommonGraphQLClient.CallerBehaviour
    def supervisor(client, opts) do
      base_name = Module.concat([client.mod(), Caller])

      {AbsintheWebSocket.Supervisor,
       [
         subscriber: client.mod(),
         url: client.websocket_api_url(opts),
         token: client.websocket_api_token(opts),
         base_name: base_name,
         async: Keyword.get(opts, :async, true)
       ]}
    end
  end
end
