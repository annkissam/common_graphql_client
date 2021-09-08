defmodule CommonGraphqlClient.MixProject do
  use Mix.Project

  @version "0.6.4"
  @url "https://github.com/annkissam/common_graphql_client"
  @maintainers [
    "Josh Adams",
    "Eric Sullivan",
    "Adi Iyengar"
  ]

  def project do
    [
      aliases: aliases(),
      app: :common_graphql_client,
      name: "CGC",
      deps: deps(),
      description: "Elixir GraphQL Client with HTTP and WebSocket Support",
      docs: docs(),
      elixir: "~> 1.6",
      preferred_cli_env: [
        analysis: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      package: package(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      version: @version
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:absinthe_websocket, "~> 0.2.2", optional: true},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev, :test], runtime: false},
      {:ecto, "~> 2.2 or ~> 3.0", optional: true},
      {:ecto_sql, "~> 3.0", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: [:test]},
      {:httpoison, "~> 1.1", optional: true},
      {:jason, ">= 1.0.0"},
      {:tesla, "~> 1.4.0", optional: true},
    ]
  end

  def docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"],
      ],
      main: "readme",
      homepage_url: @url,
      source_url: @url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp package do
    [
      name: :common_graphql_client,
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{github: @url},
      files: [
        "lib",
        "priv/npm/npm_graphql.js",
        "priv/npm/package-lock.json",
        "priv/npm/package.json",
        "mix.exs",
        "README*",
        "LICENSE*",
        "CHANGELOG.md"
      ]
    ]
  end

  defp aliases do
    [publish: ["hex.publish", &git_tag/1]]
  end

  defp git_tag(_args) do
    System.cmd("git", ["tag", "v" <> Mix.Project.config()[:version]])
    System.cmd("git", ["push", "--tags"])
  end
end
