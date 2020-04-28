defmodule CommonGraphQLClient.Client do
  @moduledoc false

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    mod = Keyword.fetch!(opts, :mod)
    http_api_token_func = Keyword.get(opts, :http_api_token_func, quote(do: fn -> nil end))
    http_api_url_func = Keyword.get(opts, :http_api_url_func, quote(do: fn -> nil end))

    websocket_api_token_func =
      Keyword.get(opts, :websocket_api_token_func, quote(do: fn -> nil end))

    websocket_api_url_func = Keyword.get(opts, :websocket_api_url_func, quote(do: fn -> nil end))

    quote location: :keep do
      require Logger

      @behaviour CommonGraphQLClient.ClientBehaviour

      @config fn ->
        unquote(otp_app) |> Application.get_env(unquote(mod), [])
      end
      @config_with_key fn key -> @config.() |> Keyword.get(key) end

      defp query_caller do
        config(:query_caller) || CommonGraphQLClient.Caller.Nil
      end

      defp subscription_caller do
        config(:subscription_caller) || CommonGraphQLClient.Caller.Nil
      end

      def config do
        unquote(otp_app)
        |> Application.get_env(unquote(mod), [])
      end

      def config(key, default \\ nil) do
        config()
        |> Keyword.get(key, default)
      end

      def init() do
        {:ok, config} =
          config()
          |> init()

        unquote(otp_app)
        |> Application.put_env(unquote(mod), config)
      end

      defp init(config) do
        if config[:load_from_system_env] do
          http_api_token = config(:http_api_token) || unquote(http_api_token_func).()
          http_api_url = config(:http_api_url) || unquote(http_api_url_func).()

          websocket_api_token =
            config(:websocket_api_token) || unquote(websocket_api_token_func).()

          websocket_api_url = config(:websocket_api_url) || unquote(websocket_api_url_func).()

          config =
            config
            |> Keyword.put(:http_api_token, http_api_token)
            |> Keyword.put(:http_api_url, http_api_url)
            |> Keyword.put(:websocket_api_token, websocket_api_token)
            |> Keyword.put(:websocket_api_url, websocket_api_url)

          {:ok, config}
        else
          {:ok, config}
        end
      end

      def http_api_token do
        config(:http_api_token)
      end

      def http_api_url do
        config(:http_api_url)
      end

      def websocket_api_token do
        config(:websocket_api_token)
      end

      def websocket_api_url do
        config(:websocket_api_url)
      end

      def mod do
        unquote(mod)
      end

      @impl CommonGraphQLClient.ClientBehaviour
      def list(term), do: handle(:list, term)

      @impl CommonGraphQLClient.ClientBehaviour
      def list!(term) do
        case list(term) do
          {:ok, resources} ->
            resources

          {:error, errors} ->
            raise "#{inspect(errors)}"
        end
      end

      @impl CommonGraphQLClient.ClientBehaviour
      def list_by(term, variables), do: handle(:list_by, term, variables)

      @impl CommonGraphQLClient.ClientBehaviour
      def list_by!(term, variables) do
        case list_by(term, variables) do
          {:ok, resources} ->
            resources

          {:error, errors} ->
            raise "#{inspect(errors)}"
        end
      end

      @impl CommonGraphQLClient.ClientBehaviour
      def get(term, id), do: handle(:get, term, id)

      @impl CommonGraphQLClient.ClientBehaviour
      def get!(term, id) do
        case get(term, id) do
          {:ok, resource} ->
            case resource do
              nil -> raise "Not Found"
              _ -> resource
            end

          {:error, errors} ->
            raise "#{inspect(errors)}"
        end
      end

      @impl CommonGraphQLClient.ClientBehaviour
      def get_by(term, variables), do: handle(:get_by, term, variables)

      @impl CommonGraphQLClient.ClientBehaviour
      def get_by!(term, variables) do
        case get_by(term, variables) do
          {:ok, resource} ->
            case resource do
              nil -> raise "Not Found"
              _ -> resource
            end

          {:error, errors} ->
            raise "#{inspect(errors)}"
        end
      end

      @impl CommonGraphQLClient.ClientBehaviour
      def subscribe_to(subscription_name, mod) do
        handle_subscribe_to(subscription_name, mod)
      end

      def supervisor(opts \\ []) do
        subscription_caller().supervisor(__MODULE__, opts)
      end

      def post(query, variables \\ %{}, opts \\ []) do
        query_caller().post(__MODULE__, query, variables, opts)
      end

      defp do_post(term, schema, query, variables \\ %{}, opts \\ []) do
        query
        |> post(variables, opts)
        |> resolve_response(Atom.to_string(term), schema)
      end

      def subscribe(term, callback, query, variables \\ %{}) do
        subscription_caller().subscribe(__MODULE__, term, callback, query, variables)
      end

      defp do_subscribe(mod, term, schema, query, variables \\ %{}) do
        callback = fn result ->
          {:ok, resource} =
            {:ok, result, nil}
            |> resolve_response(Atom.to_string(term), schema)

          apply(mod, :receive, [term, resource])
        end

        subscribe(term, callback, query, variables)
      end

      defp handle(action, term), do: raise("No handler for (#{action}, #{term})")

      defp handle(action, term, variables),
        do: raise("No handler for (#{action}, #{term}, #{variables})")

      defp handle_subscribe_to(subscription_name, mod),
        do: raise("No subscription handler for (#{subscription_name}, #{mod})")

      defp handle_absorb(subscription_name, data) do
        raise "No absorption handler for (#{subscription_name}, with data #{inspect(data)})"
      end

      def resolve_response({:ok, data, errors}, key, nil) do
        log_errors(errors)
        {:ok, Map.get(data, key)}
      end

      def resolve_response({:ok, data, errors}, key, schema) do
        log_errors(errors)

        data =
          data
          |> Map.get(key)
          |> to_schema(schema)

        {:ok, data}
      end

      def resolve_response({:error, errors}, _, _), do: {:error, errors}

      defp to_schema(nil, _), do: nil

      defp to_schema(resources_params, schema) when is_list(resources_params) do
        Enum.map(resources_params, &to_schema(&1, schema))
      end

      defp to_schema(resource_params, schema) when is_map(resource_params) do
        schema
        |> apply(:changeset, [struct(schema), resource_params])
        |> Ecto.Changeset.apply_changes()
      end

      defp log_errors(nil), do: :ok

      defp log_errors(errors),
        do: Logger.warn("Errors in reply: #{inspect(errors)}")

      defoverridable handle: 2,
                     handle: 3,
                     handle_subscribe_to: 2,
                     http_api_token: 0,
                     websocket_api_token: 0
    end
  end
end
