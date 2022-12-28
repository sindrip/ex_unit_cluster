# ExUnit Cluster

NOTE: Requires OTP 25

Spin up dynamic clusters in ExUnit tests with no special setup necessary.

You can run normal tests, alongside clustered tests.

To run distributed tests simply use `ExUnit.Cluster.Case` in a test module
```elixir
defmodule MyTest do
  use ExUnit.Cluster.Case, async: true

  test "I can spin up a 3 node cluster", ctx do
    cluster_config =
      ctx.cluster_config
      |> ExUnit.Cluster.spawn_node()
      |> ExUnit.Cluster.spawn_node()
      |> ExUnit.Cluster.spawn_node()

    nodes = ExUnit.Cluster.nodes(cluster_config)

    res =
      :erpc.multicall(nodes, Node, :list, [[:visible, :this]])
      |> Enum.flat_map(fn {_, y} -> y end)

    assert length(res) == 9
    assert MapSet.size(MapSet.new(res)) == 3
  end
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `cluster_case` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exunit_cluster, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/cluster_case>.
