defmodule Mix.Tasks.Graphql.ValidateQuery do
  @moduledoc """
  Mix task to call static query validator
  """

  use Mix.Task

  @tsk "mix graphql.validate_query"

  @info """
  #{@tsk} expects a query argument and either a schema string or a file path as
  an option:
      $ `#{@tsk} -f /path/to/schema.json <query-string-to-validate>`

  Usage:
    # With path to schema.json file
      $ `#{@tsk} -f /path/to/schema.json <query-string-to-validate>`

    # With raw schema json string
      $ `#{@tsk} -s <schema-string> <query-string-to-validate>`

    # With a custom validator (defaults to npm_graphql)
      $ `#{@tsk} -f /path/to/schema.json -v native <query-string-to-validate>`

  Options:

  Option                   Alias        Description
  --------------------------------------------------------------------------
  --validation-strategy     -v          Validation strategy to validate the
                                        query:
                                        Defaults to npm_graphql
                                        Currently only supports: npm_graphql

  --file                    -f          File path for schema.json
                                        Either file path or schema string is
                                        required

  --schema                  -s          Schema json raw string
                                        Either file path or schema string is
                                        required

  --help                    -h          Prints this info

  """

  @switches [
    validation_strategy: :string,
    file: :string,
    schema: :string,
    help: :boolean
  ]

  @aliases [
    v: :validation_strategy,
    f: :file,
    s: :schema,
    h: :help
  ]

  @default_opts [
    validation_strategy: "npm_graphql"
  ]

  alias CommonGraphqlClient.StaticValidator

  @shortdoc "Validates a query string against a given schema"
  def run(args) do
    try do
      {opts, parsed, _} =
        OptionParser.parse(args, switches: @switches, aliases: @aliases)

      params =
        @default_opts
        |> Keyword.merge(opts)
        |> Enum.into(%{})

      process_options(params, parsed)
    rescue
      RuntimeError -> mix_raise()
      MatchError -> mix_raise()
    end
  end

  defp process_options(%{help: true}, []) do
    Mix.shell().info @info
  end

  defp process_options(%{file: path, validation_strategy: validation}, [query]) do
    StaticValidator.validate(query, validation, schema_path: path)
  end

  defp process_options(%{schema: str, validation_strategy: validation}, [query]) do
    StaticValidator.validate(query, validation, schema_string: str)
  end

  defp process_options(_, _) do
    mix_raise()
  end

  def mix_raise do
    Mix.raise """
    Bad options or arguments. Refer to help page

    #{@info}
    """
  end
end
