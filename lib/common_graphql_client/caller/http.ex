defmodule CommonGraphQLClient.Caller.Http do
  @behaviour CommonGraphQLClient.CallerBehaviour

  @impl CommonGraphQLClient.CallerBehaviour
  def post(client, query, variables \\ []) do
    HTTPoison.post(client.api_url, query, [{"Content-Type", "application/json"}, {"authorization", "Bearer #{client.api_token}"}])
  end

  @impl CommonGraphQLClient.CallerBehaviour
  def subscribe(_client, _subscription_name, _callback, _query, _variables \\ []) do
    nil
  end

  @impl CommonGraphQLClient.CallerBehaviour
  def supervisor(_client), do: nil
end
