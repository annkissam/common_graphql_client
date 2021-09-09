# CommonGraphqlClient (CGC)

[![Module Version](https://img.shields.io/hexpm/v/common_graphql_client.svg)](https://hex.pm/packages/common_graphql_client)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/common_graphql_client/)
[![Total Download](https://img.shields.io/hexpm/dt/common_graphql_client.svg)](https://hex.pm/packages/common_graphql_client)
[![License](https://img.shields.io/hexpm/l/common_graphql_client.svg)](https://github.com/annkissam/common_graphql_client/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/annkissam/common_graphql_client.svg)](https://github.com/annkissam/common_graphql_client/commits/master)

An Elixir library for generating GraphQL clients.

Adapters are provided for both HTTP (using [HTTPoison](https://github.com/edgurgel/httpoison)) and WebSockets (using [AbsintheWebSocket](https://github.com/annkissam/absinthe_websocket)). Both adapters support GraphQL queries, whereas WebSockets are required for subscriptions.

This library also supports client-side query validation using `nodejs`.

## Contents

- [Documentation](#documentation)
- [Installation](#Installation)
- [Context](#Context)
- [Client](#Client)
- [Ecto Schemas](#Ecto-Schemas)
- [GraphQL Queries](#GraphQL-Queries)
- [GraphQL Subscriptions](#GraphQL-Subscriptions)
- [Security](#Security)
    * [Client Security](#Client-Security)
    * [HTTP Server](#HTTP-Server)
    * [WebSocket Server](#WebSocket-Server)
- [Client Query Validation](#Client-Query-Validation)
    * [Using NPM](#Using-Npm)
    * [Using Native Elixir](#Using-Native-Elixir)


## Documentation

Docs can be found at [https://hexdocs.pm/common_graphql_client](https://hexdocs.pm/common_graphql_client).

A complete walkthrough can be found on the [Annkissam Alembic](https://www.annkissam.com/elixir/alembic/posts/2018/07/13/graphql-subscriptions-connecting-phoenix-applications-with-absinthe-and-websockets.html). It also has an associated [demo](https://github.com/annkissam/absinthe_websocket_demo).

## Installation

Add `:common_graphql_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:common_graphql_client, "~> 0.6.0"},
    {:httpoison, "~> 1.1"},            # If using HTTP queries
    {:absinthe_websocket, "~> 0.2.0"}, # If using WebSocket subscriptions (or WebSocket queries)
  ]
end
```

An example Mix config:

```elixir
config :my_app, MyAppApi.Context,
  client: MyAppApi.Client,
  query_caller: CommonGraphQLClient.Caller.Http,             # If using HTTP queries. You can also use the WebSocket Caller.
  http_api_url: "http://127.0.0.1:4000/api",                 # The URL for the HTTP Client
  subscription_caller: CommonGraphQLClient.Caller.WebSocket, # If using WebSocket subscriptions
  websocket_api_url: "ws://127.0.0.1:4000/socket/websocket"  # The URL for the WebSocket Client
```

(optional) If you're using absinthe_websocket, it has a supervisor that must be added to your supervision tree. This will be application specific:

```elixir
    children = [
      ...
    ] ++ [MyAppApi.Client.supervisor()]

    Supervisor.init(children, strategy: :one_for_one)
```

## Context

The main entry point to the client will be the context. You can add additional methods, but it knows about `[:list, :list_by, :get, :get_by]` and their corresponding `!` methods.

The context is also responsible for implementing a `subscibe/0` method (if using subscriptions). That method is called when the initial connection is made (to initiate any subscriptions) and on re-connection (to re-establish the subscriptions). It can also perform any initiation that needs to happen when the connection is established (for instance, syncing missing data). After the subscription is made, each notification will call the `receive\2` method.

```elixir
defmodule MyAppApi.Context do
  use CommonGraphQLClient.Context,
    otp_app: :my_app

  # Identical to calling MyAppApi.Context.list(:employees)
  def list_employees do
    list(:employees)
  end

  def find_employee_by_email!(email) do
    get_by(:employees, %{employee_email: email})
  end

  def subscribe do
    # NOTE: This will call __MODULE__.receive(:employee_created, employee) when data is received
    client().subscribe_to(:employee_created, __MODULE__)

    # (optional)
    # sync_missing_data()
  end

  def receive(:employee_created, employee) do
    # do something with the created employee
  end
end
```

Your use case might necessitate the `receive\2` method exist on another module. The second parameter of `subscribe_to` allows a module to be specified. The code changes would look like this:

```elixir
defmodule MyAppApi.Context do
  ...

  def subscribe do
    client().subscribe_to(:employee_created, EmployeeNotificationHandler)
  end
end

defmodule EmployeeNotificationHandler do
  def receive(:employee_created, employee) do
    ...
  end
end
```

## Client

Your application will need a client. It will be responsible for turning symbols into various GraphQL Queries and Subscriptions. It'll also map the returned results into Ecto schemas. By calling `use CommonGraphQLClient.Client`, several methods will be made available. The client is responsible for implementing `handle\2`, `handle\3`, and `handle_subscribe_to\2` methods for each call the context makes:

```elixir
defmodule MyAppApi.Client do
  use CommonGraphQLClient.Client,
    otp_app: :my_app,
    mod: MyAppApi.Context

  defp handle(:list, :employees) do
    do_post(
      :employees,
      MyAppApi.Schema.Employee,
      MyAppApi.Query.Employee.list()
    )
  end

  defp handle(:get, :employee, id),
    do: handle(:get_by, :employee, %{id: id})

  defp handle(:get_by, :employee, variables) do
    do_post(
      :employee,
      MyAppApi.Schema.Employee,
      MyAppApi.Query.Employee.get_by(variables),
      variables
    )
  end

  defp handle_subscribe_to(:employee_created, mod) do
    do_subscribe(
      mod,
      :employee_created,
      MyAppApi.Schema.Employee,
      MyAppApi.Subscription.Employee.employee_created()
    )
  end
end
```

## Ecto Schemas

The client will map results into an ecto schema:

```elixir
defmodule MyAppApi.Schema.Employee do
  use CommonGraphQLClient.Schema

  api_schema do
    field :id, :integer
    field :name, :string
    field :email, :string
  end

  @cast_params ~w(
    id
    name
    email
  )a

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @cast_params)
  end
end
```

By adjusting the changeset you can also map GraphQL associations into additional structs. For example, using [cast_embed/3](https://hexdocs.pm/ecto/Ecto.Changeset.html#cast_embed/3):

```elixir
defmodule MyAppApi.Schema.Employee do
  use CommonGraphQLClient.Schema

  api_schema do
    field :id, :integer
    field :name, :string

    embeds_many :email_records, EmailRecord do
      field :email, :string
    end
  end

  @cast_params ~w(
    id
    name
  )a

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @cast_params)
    |> cast_embed(:email_records, with: &email_record_changeset/2)
  end

  defp email_record_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:email])
  end
end
```

## GraphQL Queries

The example client suggests organizing GraphQL Queries using modules. A module approach would look like this:

```elixir
defmodule MyAppApi.Query.Employee do
  @moduledoc """
  Employee GraphQL queries
  """

  @doc false
  def list do
    """
    query {
      employees {
        id
        name
        email
      }
    }
    """
  end

  def get_by(%{email: _}) do
    """
    query get_employee($email: String) {
      employee(email: $email) {
        id
        name
      }
    }
    """
  end
end
```

## GraphQL Subscriptions

Similar to queries, the code to initiate subscriptions can be organized using modules:

```elixir
defmodule MyAppApi.Subscription.Employee do
  @moduledoc """
  Subscription adapter module Employee
  """

  @doc false
  def employee_created do
    """
    subscription {
      employee_created {
        id
        name
        email
      }
    }
    """
  end
end
```

## Security

### Client Security

The HTTP Client can send `Bearer` tokens, whereas the WebSocket can send a token as a query param. Since these credentials should not be in source control, this library provides a way to set them at runtime. First, update the Mix config:

```elixir
config :my_app, MyAppApi.Context,
  ...
  load_from_system_env: true # add this
```

Second, update your client:

```elixir
use CommonGraphQLClient.Client,
  ...
  http_api_token_func: fn -> System.get_env("YOUR_API_TOKEN") || raise "ENV Not Set: YOUR_API_TOKEN ENV" end
  websocket_api_token_func: fn -> System.get_env("YOUR_API_TOKEN") || raise "ENV Not Set: YOUR_API_TOKEN ENV" end
```

And finally, call the `init\0` function from your application supervisor:

```elixir
defmodule MyApp.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    MyAppApi.Client.init()

    ...
  end
end
```

Alternatively, `http_api_token\0` and `websocket_api_token\0` can be overridden in the client to support other use cases.

### HTTP Server

While this package supports creating clients, if you're also building the GraphQL API in Phoenix we can make some (simple) suggestions. These examples will use a shared token. They'll also use [secure_compare](https://github.com/plackemacher/secure_compare) to mitigate [timing attacks](http://sudo.icalialabs.com/a-short-story-on-timming-attack/). Your API will require more complexity if it needs to support multiple users or to differentiate between clients.

A plug added to the router can secure your GraphQL API endpoint:

```elixir
pipeline :api do
  plug(:accepts, ["json"])
  plug Api.Authentication # add this
end
```

```elixir
# This is based on the Absinthe authentication documentation:
# https://hexdocs.pm/absinthe/context-and-authentication.html
defmodule Api.Authentication do
  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    conn
    |> fetch_token()
    |> authorize_token()
    |> case do
      :ok -> conn
        |> put_private(:absinthe, %{context: %{authorized: true}})
      _ -> conn
        |> send_resp(401, "Unauthorized")
        |> halt
    end
  end

  def fetch_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end

  def authorize_token(nil), do: :error
  def authorize_token(""), do: :error

  def authorize_token(token) do
    case SecureCompare.compare(token, secret_token()) do
      true -> :ok
      _ -> :error
    end
  end

  def secret_token do
    System.get_env("YOUR_API_TOKEN")
  end
end

```

### WebSocket Server

To secure the WebSocket connection, update user_socket:

```elixir
defmodule MyAppWeb.UserSocket do
  ...

  def connect(%{"token" => token} = params, socket) do
    case SecureCompare.compare(token, Api.Authentication.secret_token()) do
      true ->
        {:ok, socket}
      _ ->
        :error
    end
  end
end
```

## Client Query Validation

- (using schema introspection result)

Query validation can be done at the client-side using schema introspection
result to get closer to real integration tests without having to run a graphql
server.

This can be done using the mix task:

`$ mix graphql.validate_query -f schema.json <raw-query>`
`$ mix graphql.validate_query -f schema.json $(cat <query.graphql-path>)`

For more usage options try the help command:

`$ mix graphql.validate_query -h`

If you don't want to use the mix task, validation can be done at a module level
by explicitly calling the static validator module:

```elixir
schema_path = "path/to/schema.json"
query_string = "{ __schema { types { name } } }"
validation_strategy = :npm_graphql
CommonGraphqlClient.StaticValidator.validate(
  query_string,
  %{validation_strategy: validation_strategy,
    schema_path: schema_path}
)
# => :ok | {:error, error}
```

Schema validation can be done using validation strategies. The default
validation strategy is using `:npm-graphql`. This requires npm and node binaries
to be available (which is for most of the phoenix development environment)

For more information on this check out the documentation and examples for
[`CommonGraphqlClient.StaticValidator.NpmGraphql`](https://hexdocs.pm/common_graphql_client/CommonGraphQLClient.StaticValidator.NpmGraphql.html#content)

### Using Npm

This uses `npm` and `node` commands to run schema validation. Make sure you
have `npm` and `node` installed.


### Using Native Elixir

This strategy will use native elixir for performing the validation.
This is work in progress

## Copyright and License

Copyright (c) 2018 Annkissam

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. See the [LICENSE.md](./LICENSE.md) file for more details.
