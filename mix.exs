defmodule ExUnitCluster.MixProject do
  use Mix.Project

  @source_url "https://github.com/sindrip/ex_unit_cluster"

  def project do
    [
      app: :ex_unit_cluster,
      version: "0.1.1",
      elixir: ">= 1.13.4",
      deps: deps(),
      package: package(),
      preferred_cli_env: [docs: :docs],
      name: "ExUnit.Cluster",
      docs: docs(),
      source_url: @source_url,
      description: description(),
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp description do
    "Spin up dynamic clusters in ExUnit tests with no special setup necessary."
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "ExUnitCluster"
    ]
  end
end
