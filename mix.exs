defmodule ExUnit.Cluster.MixProject do
  use Mix.Project

  def project do
    [
      app: :exunit_cluster,
      version: "0.1.0",
      elixir: ">= 1.13.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:ex_unit]
      ]
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
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:docs], runtime: false}
    ]
  end
end
