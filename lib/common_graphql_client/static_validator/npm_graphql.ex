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

  ## Examples:

    # When query is valid
    iex> alias CommonGraphqlClient.StaticValidator.NpmGraphql
    iex> schema_string = "\\ntype Author {\\n firstName: String\\n  lastName: String\\n  }\\n  type Query {\\n author(id: Int!): Author\\n  }\\n"
    iex> query_string = "{ __typename }"
    iex> NpmGraphql.validate(query_string, schema_string)
    :ok

    # When query is invalid
    iex> alias CommonGraphqlClient.StaticValidator.NpmGraphql
    iex> schema_string = "\\ntype Author {\\n firstName: String\\n  lastName: String\\n  }\\n  type Query {\\n author(id: Int!): Author\\n  }\\n"
    iex> query_string = "bad query string"
    iex> {:error, error} = NpmGraphql.validate(query_string, schema_string)
    iex> Regex.match?(~r/Unexpected Name \\"bad\\"/, error)
    true

    # When schema is invalid
    iex> schema_string = "bad schema"
    iex> alias CommonGraphqlClient.StaticValidator.NpmGraphql
    iex> query_string = "{ __typename }"
    iex> {:error, error} = NpmGraphql.validate(query_string, schema_string)
    iex> Regex.match?(~r/Unexpected Name \\"bad\\"/, error)
    true
  """
  @impl true
  def validate(query_string, schema_string) do
    with :ok <- check_node(),
         # there is a chance that this might be the case
         :ok <- check_npm(),
         :ok <- npm_install() do
      node_run_validation(query_string, schema_string)
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

  defp node_run_validation(query_string, schema_string) do
    result =
      System.cmd(
        "node",
        [node_file_path()],
        cd: node_path(),
        stderr_to_stdout: true,
        env: [{"SCHEMA_STRING", schema_string}, {"QUERY_STRING", query_string}]
      )

    case result do
      {_output, 0} -> :ok
      {error, 1} -> {:error, error}
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
