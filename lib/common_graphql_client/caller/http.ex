if Code.ensure_loaded?(HTTPoison) do
  defmodule CommonGraphQLClient.Caller.Http do
    @moduledoc false

    @behaviour CommonGraphQLClient.CallerBehaviour

    @impl CommonGraphQLClient.CallerBehaviour
    def post(client, query, variables \\ [], opts \\ []) do
      body =
        %{
          query: query,
          variables: variables
        }
        |> Poison.encode!()

      case HTTPoison.post(
             client.http_api_url(),
             body,
             [
               {"Content-Type", "application/json"},
               {"authorization", "Bearer #{client.http_api_token()}"}
             ],
             Keyword.get(opts, :http_opts, [])
           ) do
        {:ok, %{body: json_body, status_code: 200}} ->
          case Poison.decode(json_body) do
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
