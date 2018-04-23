defmodule CommonGraphQLClient.Client do
  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    mod = Keyword.fetch!(opts, :mod)
    env_var_token = Keyword.fetch!(opts, :env_var_token)
    env_var_url = Keyword.fetch!(opts, :env_var_url)

    quote do
      @behaviour CommonGraphQLClient.ClientBehaviour

      @config fn ->
        unquote(otp_app) |> Application.get_env(unquote(mod), [])
      end
      @config_with_key fn key -> @config.() |> Keyword.get(key) end
      @caller @config_with_key.(:caller) || CommonGraphQLClient.Caller.Websocket

      def config do
        unquote(otp_app)
        |> Application.get_env(unquote(mod), [])
      end

      def config(key, default \\ nil) do
        config()
        |> Keyword.get(key, default)
      end

      def init() do
        {:ok, config} = config()
                        |> init()

        unquote(otp_app)
        |> Application.put_env(unquote(mod), config)
      end

      defp init(config) do
        if config[:load_from_system_env] do
          api_token = System.get_env(unquote(env_var_token)) || raise system_env_err_msg(unquote(env_var_token))
          api_url = System.get_env(unquote(env_var_url)) || raise system_env_err_msg(unquote(env_var_url))

          config = config
                   |> Keyword.put(:api_token, api_token)
                   |> Keyword.put(:api_url, api_url)

          {:ok, config}
        else
          {:ok, config}
        end
      end

      defp system_env_err_msg(var) do
        "expected the #{var} environment variable to be set"
      end

      def api_token do
        config(:api_token)
      end

      def api_url do
        config(:api_url)
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
            raise "#{inspect errors}"
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
            raise "#{inspect errors}"
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
            raise "#{inspect errors}"
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
            raise "#{inspect errors}"
        end
      end

      @impl CommonGraphQLClient.ClientBehaviour
      def subscribe_to(subscription_name, mod) do
        handle_subscribe_to(subscription_name, mod)
      end

      def supervisor() do
        @caller.supervisor(__MODULE__)
      end

      def post(query, variables \\ %{}) do
        @caller.post(__MODULE__, query, variables)
      end

      defp do_post(term, schema, query, variables \\ %{}) do
        query
        |> post(variables)
        |> resolve_response(Atom.to_string(term), schema)
      end

      def subscribe(term, callback, query, variables \\ %{}) do
        @caller.subscribe(__MODULE__, term, callback, query, variables)
      end

      defp do_subscribe(mod, term, schema, query, variables \\ %{}) do
        callback = fn(result) ->
          {:ok, resource} = {:ok, result}
                            |> resolve_response(Atom.to_string(term), schema)

          apply(mod, :receive, [term, resource])
        end

        subscribe(term, callback, query, variables)
      end

      defp handle(action, term), do: raise "No handler for (#{action}, #{term})"
      defp handle(action, term, variables), do: raise "No hander for (#{action}, #{term}, #{variables})"

      defp handle_subscribe_to(subscription_name, mod), do: raise "No subscription handler for (#{subscription_name}, #{mod})"

      def resolve_response({:ok, data}, key, schema) do
        data = data
               |> Map.get(key)
               |> to_schema(schema)

        {:ok, data}
      end
      def resolve_response({:error, errors}, _, _), do: {:error, errors}

      defp to_schema(nil, _), do: nil
      defp to_schema(resources_params, schema) when is_list(resources_params) do
        Enum.map(resources_params, &(to_schema(&1, schema)))
      end
      defp to_schema(resource_params, schema) when is_map(resource_params) do
        schema
        |> apply(:changeset, [struct(schema), resource_params])
        |> Ecto.Changeset.apply_changes()
      end

      defoverridable [handle: 2, handle: 3, handle_subscribe_to: 2]
    end
  end

end
