# ExUnit Cluster

<!-- README START -->

[![Elixir CI](https://github.com/sindrip/ex_unit_cluster/actions/workflows/elixir.yaml/badge.svg)](https://github.com/sindrip/ex_unit_cluster/actions/workflows/elixir.yaml)
[![Module Version](https://img.shields.io/hexpm/v/ex_unit_cluster.svg)](https://hex.pm/packages/ex_unit_cluster)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/ex_unit_cluster)
[![Total Download](https://img.shields.io/hexpm/dt/ex_unit_cluster.svg)](https://hex.pm/packages/ex_unit_cluster)
[![License](https://img.shields.io/hexpm/l/ex_unit_cluster.svg)](https://github.com/sindrip/ex_unit_cluster/blob/master/LICENSE)

Spin up dynamic clusters in ExUnit tests with no special setup necessary.

Provides helpers for writing tests on nodes in isolated clusters, you can run normal tests alongside clustered tests.

This library relies on the [:peer](https://www.erlang.org/doc/man/peer.html)
module which was introduced in OTP 25 and is first supported in elixir version 1.13.4.

## Examples

The most straightforward way to start using `ExUnitCluster` for a distributed test,
is to start `ExUnitCluster.Manager` inside the test.

```elixir
defmodule SimpleTest do
  use ExUnit.Case, async: true

  test "start node in test case", ctx do
    # 1) Start the cluster manager under the test supervisor
    cluster = start_supervised!({ExUnitCluster.Manager, ctx})
    # 2) Start a node linked to the given manager
    node = ExUnitCluster.start_node(cluster)

    # 3) Make an RPC to the node
    node_name = ExUnitCluster.call(cluster, node, Node, :self, [])
    refute Node.self() == node_name
  end
end
```

If you want all tests in a module to use a cluster you can start `ExUnitCluster.Manager` in
`ExUnit.Callbacks.setup/1`.

```elixir
defmodule ClusterTest do
  use ExUnit.Case, async: true

  setup ctx do
    # 1) Start a cluster manager under the test supervisor for each test
    cluster = start_supervised!({ExUnitCluster.Manager, ctx})
    [cluster: cluster]
  end

  test "start node in test", %{cluster: cluster} do
    # 2) Start a node in this test
    node = ExUnitCluster.start_node(cluster)

    # 3) Make an RPC to the node
    node_name = ExUnitCluster.call(cluster, node, Node, :self, [])
    refute Node.self() == node_name
  end
end
```

Which is exactly what `ExUnitCluster.Case` does

```elixir
defmodule ReadmeClusterTest do
  use ExUnitCluster.Case, async: true

  test "start node in test", %{cluster: cluster} do
    node = ExUnitCluster.start_node(cluster)

    node_name = ExUnitCluster.call(cluster, node, Node, :self, [])
    refute Node.self() == node_name
  end
end
```

<!-- README END -->

## Installation

Add `ex_unit_cluster` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_unit_cluster, "~> 0.6.0"}
  ]
end
```
