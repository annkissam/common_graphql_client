defmodule CommonGraphqlClient.StaticValidator do
  @moduledoc """
  Validates a query against a static graphql schema
  """

  @doc """
  This method validates a query against a graphql schema and returns `:ok` if
  the query is valid or returns `{:error, reason}`.

  This method takes:
  * a `query`: A graphql query string
  * `validation_strategy`: Way to validate schema. Could be done in multiple
    ways:
    - `:npm_graphql` (needs `npm` cli) Uses npm calls to validate query
    - `:native` (todo: parse schema in elixir) Will validate in pure elixir
  * Options: Options for validation include:
    - `schema_string`: Contents on graphql schema to validate the query for
    - `schema_path`: Path to the file containing graphql schema

  ## Examples:

    # When query is valid
    iex> schema_string = "\\ntype Author {\\n firstName: String\\n  lastName: String\\n  }\\n  type Query {\\n author(id: Int!): Author\\n  }\\n"
    iex> query_string = "{ __typename }"
    iex> validation_strategy = :npm_graphql
    iex> CommonGraphqlClient.StaticValidator.validate(query_string, validation_strategy, schema_string: schema_string)
    :ok

    # When query is invalid
    iex> schema_string = "\\ntype Author {\\n firstName: String\\n  lastName: String\\n  }\\n  type Query {\\n author(id: Int!): Author\\n  }\\n"
    iex> query_string = "bad query string"
    iex> validation_strategy = :npm_graphql
    iex> {:error, error} = CommonGraphqlClient.StaticValidator.validate(query_string, validation_strategy, schema_string: schema_string)
    iex> Regex.match?(~r/Unexpected Name \\"bad\\"/, error)
    true

    # When schema is invalid
    iex> schema_string = "bad schema"
    iex> query_string = "{ __typename }"
    iex> validation_strategy = :npm_graphql
    iex> {:error, error} = CommonGraphqlClient.StaticValidator.validate(query_string, validation_strategy, schema_string: schema_string)
    iex> Regex.match?(~r/Unexpected Name \\"bad\\"/, error)
    true

    # When validation_strategy is native
    iex> schema_string = "\\ntype Author {\\n firstName: String\\n  lastName: String\\n  }\\n  type Query {\\n author(id: Int!): Author\\n  }\\n"
    iex> query_string = "{ __typename }"
    iex> validation_strategy = :native
    iex> CommonGraphqlClient.StaticValidator.validate(query_string, validation_strategy, schema_string: schema_string)
    ** (RuntimeError) Not implemented
  """
  @spec validate(String.t(), atom(), Keyword.t()) :: :ok | {:error, term()}
  def validate(query_string, mod, opts)

  def validate(query_string, validation_strategy, schema_path: schema_path) do
    case File.read(schema_path) do
      {:ok, contents} ->
        validate(query_string, validation_strategy, schema_string: contents)
      {:error, error} ->
        {:error, error}
    end
  end

  def validate(query_string, :npm_graphql, schema_string: schema_string) do
    with :ok <- check_node(),
         :ok <- generate_js_file(query_string, schema_string),
         :ok <- node_run_file(temp_file_path())
    do
      # remove temp file after validation
      File.rm(temp_file_path())
    else
      {:error, error} ->
        # remove temp file after validation
        File.rm(temp_file_path())
        {:error, error}
    end
  end

  def validate(_query_string, :native, _opts) do
    raise "Not implemented"
  end

  defp check_node do
    case System.cmd("node", ["-h"]) do
      {_output, 0} -> :ok
      {error, 1} -> {:error, error}
    end
  end

  defp generate_js_file(query_string, schema_string) do
    js_contents =
      graphql_js_template_path()
      |> EEx.eval_file(
        query_string: query_string,
        schema_string: schema_string
      )

    case File.write(temp_file_path(), js_contents) do
      :ok -> :ok
      {:error, error} -> {:error, error}
    end
  end

  defp graphql_js_template_path do
    priv = :code.priv_dir(:common_graphql_client)
    Path.join([priv, "templates", "npm_graphql.js.eex"])
  end

  defp node_run_file(file_path) do
    case System.cmd("node", [file_path], cd: node_path(), stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {error, 1} -> {:error, error}
    end
  end

  defp temp_file_path do
    temp_file_name = "temp.js"
    Path.join(node_path(), temp_file_name)
  end

  defp node_path do
    priv = :code.priv_dir(:common_graphql_client)
    Path.join([priv, "npm"])
  end
end
