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
      schema_path = "./test/support/example_schema.json"
      schema_string = File.read!(schema_path)
      query_string = "{ __schema { types { name } } }"

      output = capture_io(fn ->
        Mix.Tasks.Graphql.ValidateQuery.run(["-s", schema_string, query_string])
      end)

      assert output =~ "Valid!"
    end

    test "validates if schema file is given" do
      schema_file = "./test/support/example_schema.json"
      query_string = "{ __schema { types { name } } }"

      output = capture_io(fn ->
        Mix.Tasks.Graphql.ValidateQuery.run(["-f", schema_file, query_string])
      end)

      assert output =~ "Valid!"
    end
  end
end
