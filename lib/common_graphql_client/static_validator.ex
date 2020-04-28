defmodule CommonGraphqlClient.StaticValidator do
  @moduledoc """
  Validates a query against a static graphql schema
  """

  @doc """
  This method validates a query against a graphql schema and returns `:ok` if
  the query is valid or returns `{:error, reason}`.

  This method takes:
  * a `query_string`: A graphql query string
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
    __MODULE__.NpmGraphql.validate(query_string, schema_string)
  end

  def validate(_query_string, :native, _opts) do
    raise "Not implemented"
  end
end
