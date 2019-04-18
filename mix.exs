defmodule CommonGraphqlClient.MixProject do
  use Mix.Project

  @version "0.3.2"
  @url "https://github.com/annkissam/common_graphql_client"
  @maintainers [
    "Josh Adams",
    "Eric Sullivan",
  ]

  def project do
    [
      app: :common_graphql_client,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: "Elixir GraphQL Client with HTTP and WebSocket Support",
      docs: docs(),
      package: package(),
      source_url: @url,
      homepage_url: @url,
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:absinthe_websocket, "~> 0.2.2", optional: true},
      {:ecto_sql, "~> 2.2 or ~> 3.0"},
      {:httpoison, "~> 1.1", optional: true},
      {:ex_doc, "~> 0.10", only: :dev},
    ]
  end

  def docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      name: :common_graphql_client,
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{github: @url},
      files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG.md"],
    ]
  end

  defp aliases do
    [publish: ["hex.publish", &git_tag/1]]
  end

  defp git_tag(_args) do
    System.cmd "git", ["tag", "v" <> Mix.Project.config[:version]]
    System.cmd "git", ["push", "--tags"]
  end
end
