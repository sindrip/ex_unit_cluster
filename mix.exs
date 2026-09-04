defmodule ExUnitCluster.MixProject do
  use Mix.Project

  @source_url "https://github.com/sindrip/ex_unit_cluster"

  def project do
    [
      app: :ex_unit_cluster,
      version: "0.7.0",
      elixir: ">= 1.15.0",
      deps: deps(),
      package: package(),
      name: "ExUnit.Cluster",
      docs: docs(),
      source_url: @source_url,
      description: description(),
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix]
      ]
    ]
  end

  def cli do
    [preferred_envs: %{docs: :docs, "hex.build": :docs, "hex.publish": :docs}]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", "usage-rules.md"],
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
