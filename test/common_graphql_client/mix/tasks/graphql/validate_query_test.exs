defmodule Mix.Tasks.Graphql.ValidateQueryTest do
  use ExUnit.Case
  doctest Mix.Tasks.Graphql.ValidateQuery

  import ExUnit.CaptureIO

  describe "run/1" do
    test "prints help" do
      output = capture_io(fn ->
        Mix.Tasks.Graphql.ValidateQuery.run(["-h"])
      end)

      assert output =~ "mix graphql.validate_query"
      assert output =~ "Usage:"
    end

    test "raises if invalid options" do
      assert_raise(Mix.Error, fn ->
        Mix.Tasks.Graphql.ValidateQuery.run(["-b"])
      end)
    end

    test "validates is schema string is given" do
      schema_string = "\ntype Author {\n firstName: String\n  lastName: String\n  }\n  type Query {\n author(id: Int!): Author\n  }\n"
      query_string = "{ __typename }"

      output = capture_io(fn ->
        Mix.Tasks.Graphql.ValidateQuery.run(["-s", schema_string, query_string])
      end)

      assert output =~ "Valid!"
    end

    test "validates if schema file is given" do
      schema_string = "\ntype Author {\n firstName: String\n  lastName: String\n  }\n  type Query {\n author(id: Int!): Author\n  }\n"
      random_file = :crypto.strong_rand_bytes(5) |> Base.url_encode64() |> binary_part(0, 5)
      schema_file = "./tmp-schema-" <> random_file <> ".json"
      File.write!(schema_file, schema_string)
      query_string = "{ __typename }"

      output = capture_io(fn ->
        Mix.Tasks.Graphql.ValidateQuery.run(["-f", schema_file, query_string])
      end)

      on_exit(fn ->
        File.exists?(schema_file) && File.rm!(schema_file)
      end)

      assert output =~ "Valid!"
    end
  end
end
