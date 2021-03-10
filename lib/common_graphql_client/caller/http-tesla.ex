if Code.ensure_loaded?(Tesla) do
  defmodule CommonGraphQLClient.Caller.HttpTesla do
    @moduledoc """
    Tesla GraphQL Adapter

    Add to the client:

      def connection(opts) do
        token = http_api_token(opts)

        middleware = [
          {Tesla.Middleware.Headers, [{"Authorization", "Bearer " <> token}]},
          {Tesla.Middleware.Headers, [{"Content-Type", "application/json"}]},
          {Tesla.Middleware.Timeout, timeout: 60_000}
        ]

        adapter = {Tesla.Adapter.Finch, name: MyAppFinch}

        Tesla.client(middleware, adapter)
      end
    """

    @behaviour CommonGraphQLClient.CallerBehaviour

    @impl CommonGraphQLClient.CallerBehaviour
    def post(client, query, variables \\ [], opts \\ []) do
      body =
        %{
          query: query,
          variables: variables
        }
        |> Jason.encode!()

      connection = Keyword.get_lazy(opts, :connection, fn -> client.connection(opts) end)
      url = client.http_api_url(opts)

      case Tesla.post(connection, url, body) do
        {:ok, %{body: json_body, status: 200}} ->
          case Jason.decode(json_body) do
            {:ok, body} ->
              {:ok, body["data"], body["errors"]}

            {:error, exception} ->
              {:error, exception}
          end

        {:error, error} ->
          {:error, error}

        {:ok, response} ->
          {:error, response}
      end
    end

    @impl CommonGraphQLClient.CallerBehaviour
    def subscribe(_client, _subscription_name, _callback, _query, _variables \\ []) do
      raise "Not Implemented"
    end

    @impl CommonGraphQLClient.CallerBehaviour
    def supervisor(_client, _opts), do: nil
  end
end
