defmodule CommonGraphQLClient.CallerBehaviour do
  @moduledoc """
  This module defines the behavior a `caller` must implement.
  """

  @callback post(client :: any, query :: String.t(), variables :: keyword()) :: any
  @callback subscribe(client :: any, subscription_name :: atom(), callback :: fun(), query :: String.t(), variables :: keyword()) :: any
  @callback supervisor(client :: any, opts :: Keyword.t()) :: {atom(), any} | no_return()
end

