defmodule CommonGraphQLClient.CallerBehaviour do
  @moduledoc """
  This module defines the behavior a `caller` must implement.

  ## Callbacks:

  * post(query, variables) -> Makes a request with the given query and variables.

  """

  @callback post(query :: String.t(), variables :: keyword()) :: any
  @callback subscribe(subscription_name :: atom(), callback :: fun(), query :: String.t(), variables :: keyword()) :: any
  @callback supervisor() :: {atom(), any} | no_return()
end

