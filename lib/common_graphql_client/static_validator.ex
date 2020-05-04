defmodule CommonGraphqlClient.StaticValidator do
  @moduledoc """
  Validates a query against a static graphql schema
  """

  @doc """
  This method validates a query against a graphql schema and returns `:ok` if
  the query is valid or returns `{:error, reason}`.

  This method takes:
  * a `query_string`: A graphql query string
  * Options: Options for validation include:
    - `schema_string`: Contents on graphql schema to validate the query for
    - `schema_path`: Path to the file containing graphql schema
    - `validation_strategy`: Way to validate schema. Could be done in multiple
    ways:
      * `:npm_graphql` (needs `npm` cli) Uses npm calls to validate query
      * `:native` (todo: parse schema in elixir) Will validate in pure elixir

  ## Examples:

    # When a schema file is given and the query is valid
    iex> schema_path = "./test/support/example_schema.json"
    iex> query_string = "{ __schema { types { name } } }"
    iex> validation_strategy = :npm_graphql
    iex> CommonGraphqlClient.StaticValidator.validate(
    ...>   query_string,
    ...>   %{ validation_strategy: validation_strategy,
    ...>      schema_path: schema_path }
    ...> )
    :ok

    # When a schema string is given and the query is valid
    iex> schema_path = "./test/support/example_schema.json"
    iex> schema_string = File.read!(schema_path)
    iex> query_string = "{ __schema { types { name } } }"
    iex> validation_strategy = :npm_graphql
    iex> CommonGraphqlClient.StaticValidator.validate(
    ...>   query_string,
    ...>   %{ validation_strategy: validation_strategy,
    ...>      schema_string: schema_string }
    ...> )
    :ok

    # When query is invalid
    iex> schema_path = "./test/support/example_schema.json"
    iex> query_string = "bad query string"
    iex> validation_strategy = :npm_graphql
    iex> {:error, error} = CommonGraphqlClient.StaticValidator.validate(
    ...>   query_string,
    ...>   %{ validation_strategy: validation_strategy,
    ...>      schema_path: schema_path }
    ...> )
    iex> Regex.match?(~r/Unexpected Name \\"bad\\"/, error)
    true

    # When schema is invalid
    iex> schema_string = "bad schema"
    iex> query_string = "{ __schema { types { name } } }"
    iex> validation_strategy = :npm_graphql
    iex> {:error, error} = CommonGraphqlClient.StaticValidator.validate(
    ...>   query_string,
    ...>   %{ validation_strategy: validation_strategy,
    ...>      schema_string: schema_string }
    ...> )
    iex> Regex.match?(~r/bad\sschema/, error)
    true

    # When validation_strategy is native
    iex> schema_string = "someschema"
    iex> query_string = "somequery"
    iex> validation_strategy = :native
    iex> CommonGraphqlClient.StaticValidator.validate(
    ...>   query_string,
    ...>   %{ validation_strategy: validation_strategy,
    ...>      schema_string: schema_string }
    ...> )
    ** (RuntimeError) Not Implemented
  """
  @spec validate(String.t(), Map.t()) :: :ok | {:error, term()}
  def validate(query_string, opts)

  def validate(query_string, %{schema_path: schema_path} = opts) do
    case File.read(schema_path) do
      {:ok, contents} ->
        opts =
          opts
          |> Map.delete(:schema_path)
          |> Map.put(:schema_string, contents)

        validate(query_string, opts)

      {:error, error} ->
        {:error, error}
    end
  end

  def validate(query_string, %{schema_string: schema_string} = opts) do
    case Map.get(opts, :validation_strategy) do
      :npm_graphql ->
        __MODULE__.NpmGraphql.validate(query_string, schema_string, opts)
      _ ->
        raise "Not Implemented"
    end
  end
end
