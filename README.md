# ExUnit Cluster

NOTE: Requires at least OTP 25.1

Spin up dynamic clusters in ExUnit tests with no special setup necessary.

You can run normal tests, alongside clustered tests.

To run distributed tests simply use `ExUnit.Cluster.Case` in a test module
```elixir
defmodule MyTest do
  use ExUnit.Cluster.Case, async: true

  test "I can spin up a 3 node cluster", ctx do
    n1 = Cluster.start_node(cluster)
    n2 = Cluster.start_node(cluster)
    n3 = Cluster.start_node(cluster)

    nodes = Cluster.get_nodes(cluster)

    assert Enum.sort([n1, n2, n3]) == Enum.sort(nodes)

    res =
      Enum.flat_map(nodes, fn n ->
        Cluster.call(cluster, n, Node, :list, [[:visible, :this]])
      end)

    assert length(res) == 9
    assert MapSet.size(MapSet.new(res)) == 3
  end
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_unit_cluster` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_unit_cluster, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_unit_cluster>.
