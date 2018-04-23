defmodule CommonGraphQLClient.ClientBehaviour do
  @callback list(atom()) :: {:ok, any} |  {:error, any}
  @callback list!(atom()) :: any | no_return()

  @callback list_by(atom(), map()) :: {:ok, any} |  {:error, any}
  @callback list_by!(atom(), map()) :: any | no_return()

  @callback get(atom(), integer()) :: {:ok, any} | {:error, any}
  @callback get!(atom(), integer()) :: any | no_return()

  @callback get_by(atom(), map()) :: {:ok, any} | {:error, any}
  @callback get_by!(atom(), map()) :: any | no_return()

  @callback subscribe_to(atom(), any) :: any | no_return()
end
