defmodule CommonGraphqlClient.StaticValidator.NpmGraphql do
  @moduledoc """
  This module uses node and graphql-tools to validate a graphql query against
  a graphql schema

  It needs `node` binary to be available
  """

  @behaviour CommonGraphqlClient.StaticValidator.ValidationStrategy

  @doc """
  This method uses node & graphql-tools validates a query against a graphql
  schema and returns `:ok` if the query is valid or returns `{:error, reason}`.

  This method takes:
  * a `query_string`: A graphql query string
  * a `schema_string`: Contents on graphql schema to validate the query for
  * Options: validate options include:
    - `variables`: Document variable values for the query (needs to be a `Map`)

  ## Examples:

      # When query is valid (schema_string)
      iex> alias CommonGraphqlClient.StaticValidator.NpmGraphql
      iex> schema_path = "./test/support/example_schema.json"
      iex> schema_string = File.read!(schema_path)
      iex> query_string = "{ __schema { types { name } } }"
      iex> NpmGraphql.validate(query_string, %{schema_string: schema_string})
      :ok

      # When query is valid (schema_path)
      iex> alias CommonGraphqlClient.StaticValidator.NpmGraphql
      iex> schema_path = "./test/support/example_schema.json"
      iex> query_string = "{ __schema { types { name } } }"
      iex> NpmGraphql.validate(query_string, %{schema_path: schema_path})
      :ok

      # When query is invalid
      iex> alias CommonGraphqlClient.StaticValidator.NpmGraphql
      iex> schema_path = "./test/support/example_schema.json"
      iex> schema_string = File.read!(schema_path)
      iex> query_string = "bad query string"
      iex> {:error, error} = NpmGraphql.validate(query_string, %{schema_string: schema_string})
      iex> Regex.match?(~r/Unexpected Name \\"bad\\"/, error)
      true

      # When schema is invalid
      iex> alias CommonGraphqlClient.StaticValidator.NpmGraphql
      iex> schema_string = "bad schema"
      iex> query_string = "{ __schema { types { name } } }"
      iex> {:error, error} = NpmGraphql.validate(query_string, %{schema_string: schema_string})
      iex> Regex.match?(~r/SyntaxError/, error)
      true

      # When query variables are passed
      iex> alias CommonGraphqlClient.StaticValidator.NpmGraphql
      iex> schema_path = "./test/support/example_schema.json"
      iex> schema_string = File.read!(schema_path)
      iex> query_string = "
      ...>   query getUser($id: ID!) {
      ...>     user(id: $id) {
      ...>       id
      ...>     }
      ...>   }
      ...> "
      iex> variables = %{id: 1}
      iex> NpmGraphql.validate(
      ...>   query_string,
      ...>   %{schema_string: schema_string, variables: variables}
      ...> )
      :ok
  """
  @impl true
  def validate(query_string, opts \\ %{}) do
    node_run_validation(query_string, opts)
  end

  def initialize do
    with :ok <- check_node(),
         :ok <- check_npm(),
         :ok <- npm_install() do
      :ok
    else
      {:error, error} -> {:error, error}
    end
  end

  defp check_node do
    case System.cmd("node", ["-h"]) do
      {_output, 0} -> :ok
      {error, 1} -> {:error, error}
    end
  end

  defp check_npm do
    case System.cmd("npm", ["help"]) do
      {_output, 0} -> :ok
      {error, 1} -> {:error, error}
    end
  end

  defp npm_install do
    case System.cmd("npm", ["install"], cd: node_path()) do
      {_output, 0} -> :ok
      {error, 1} -> {:error, error}
    end
  end

  defp node_run_validation(query_string, %{schema_path: schema_path} = opts) do
    document_variables =
      opts
      |> Map.get(:variables, %{})
      |> Jason.encode!()

    result =
      System.cmd(
        "node",
        [node_file_path()],
        stderr_to_stdout: true,
        env: [
          {"DOCUMENT_VARIABLES", document_variables},
          {"QUERY_STRING", query_string},
          {"SCHEMA_PATH", schema_path}
        ]
      )

    case result do
      {_output, 0} ->
        :ok

      {error, 1} ->
        {:error, error}

      _ ->
        raise inspect(result)
    end
  end

  defp node_run_validation(query_string, %{schema_string: schema_string} = opts) do
    document_variables =
      opts
      |> Map.get(:variables, %{})
      |> Jason.encode!()

    result =
      System.cmd(
        "node",
        [node_file_path()],
        stderr_to_stdout: true,
        env: [
          {"DOCUMENT_VARIABLES", document_variables},
          {"QUERY_STRING", query_string},
          {"SCHEMA_STRING", schema_string}
        ]
      )

    case result do
      {_output, 0} ->
        :ok

      {error, 1} ->
        {:error, error}

      _ ->
        raise inspect(result)
    end
  end

  defp node_file_path do
    file_name = "npm_graphql.js"
    Path.join(node_path(), file_name)
  end

  defp node_path do
    priv = :code.priv_dir(:common_graphql_client)
    Path.join([priv, "npm"])
  end
end
