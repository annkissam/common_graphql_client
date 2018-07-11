if Code.ensure_loaded?(AbsintheWebSocket) do
  defmodule CommonGraphQLClient.Caller.Websocket do
    @behaviour CommonGraphQLClient.CallerBehaviour

    @impl CommonGraphQLClient.CallerBehaviour
    def post(client, query, variables \\ []) do
      query_server_name = Module.concat([client.mod(), Caller, QueryServer])

      AbsintheWebSocket.QueryServer.post(query_server_name, query, variables)
    end

    @impl CommonGraphQLClient.CallerBehaviour
    def subscribe(client, subscription_name, callback, query, variables \\ []) do
      subscription_server_name = Module.concat([client.mod(), Caller, SubscriptionServer])

      AbsintheWebSocket.SubscriptionServer.subscribe(subscription_server_name, subscription_name, callback, query, variables)
    end

    @impl CommonGraphQLClient.CallerBehaviour
    def supervisor(client) do
      base_name = Module.concat([client.mod(), Caller])

      {AbsintheWebSocket.Supervisor, [subscriber: client.mod(), url: client.api_url(), token: client.api_token(), base_name: base_name]}
    end
  end
end
