defmodule Tracer.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :tracer,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        check: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],

      # Docs
      name: "Tracer",
      source_url: "https://github.com/systemic-engineer/tracer",
      homepage_url: "https://github.com/systemic-engineer/tracer",
      description: "Generic computation trace with visual tree rendering",
      docs: docs(),

      # Hex
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.35", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "credo --strict",
        "test"
      ]
    ]
  end

  defp docs do
    [
      main: "Tracer",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/systemic-engineer/tracer"},
      maintainers: ["Reed <reed@systemi.engineer>"]
    ]
  end
end
