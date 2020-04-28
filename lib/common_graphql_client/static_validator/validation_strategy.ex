defmodule CommonGraphqlClient.StaticValidator.ValidationStrategy do
  @moduledoc """
  Defines behaviour for validation strategies for static validations
  """

  @doc """
  Validates a query_string against a schema_string
  """
  @callback validate(query_string :: String.t(), schema_string :: String.t()) :: :ok | {:error, term()}
end
