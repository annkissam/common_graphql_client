defmodule CommonGraphQLClient.Caller.Nil do
  @moduledoc false

  @behaviour CommonGraphQLClient.CallerBehaviour

  @impl CommonGraphQLClient.CallerBehaviour
  def post(_client, _query, _variables \\ [], _opts \\ []) do
    {:error, "Not Implemented"}
  end

  @impl CommonGraphQLClient.CallerBehaviour
  def subscribe(_client, _subscription_name, _callback, _query, _variables \\ []) do
    raise "Not Implemented"
  end

  @impl CommonGraphQLClient.CallerBehaviour
  def supervisor(_client, _opts), do: nil
end
