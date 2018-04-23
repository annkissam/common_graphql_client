defmodule CommonGraphQLClient.Caller.Nil do
  @behaviour CommonGraphQLClient.CallerBehaviour

  @impl CommonGraphQLClient.CallerBehaviour
  def post(_client, _query, _variables \\ []) do
    {:error, "Not Implemented"}
  end

  @impl CommonGraphQLClient.CallerBehaviour
  def subscribe(_client, _subscription_name, _callback, _query, _variables \\ []) do
    nil
  end

  @impl CommonGraphQLClient.CallerBehaviour
  def supervisor(_client), do: nil
end
