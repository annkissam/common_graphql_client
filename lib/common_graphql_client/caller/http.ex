if Code.ensure_loaded?(HTTPoison) do
  defmodule CommonGraphQLClient.Caller.Http do
    @behaviour CommonGraphQLClient.CallerBehaviour

    @impl CommonGraphQLClient.CallerBehaviour
    def post(client, query, variables \\ []) do
      body = %{
        query: query,
        variables: variables
      } |> Poison.encode!

      case HTTPoison.post(client.api_url, body, [{"Content-Type", "application/json"}, {"authorization", "Bearer #{client.api_token}"}]) do
        {:ok, %{body: json_body}} ->
          body = Poison.decode!(json_body)
          {:ok, body["data"]}
        {:error, error} ->
          {:error, error}
      end
    end

    @impl CommonGraphQLClient.CallerBehaviour
    def subscribe(_client, _subscription_name, _callback, _query, _variables \\ []) do
      raise "Not Implemented"
    end

    @impl CommonGraphQLClient.CallerBehaviour
    def supervisor(_client), do: nil
  end
end
