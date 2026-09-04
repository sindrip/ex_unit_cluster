# ExUnitCluster Usage Rules

`ex_unit_cluster` provides helpers for spinning up dynamic Erlang/OTP cluster nodes in ExUnit tests using Erlang's `:peer` module (requires Erlang/OTP 25+).

## Test Case Setup

### 1. Isolated Cluster Per Test (Default)
Use `ExUnitCluster.Case` in test modules. It automatically starts an `ExUnitCluster.Manager` under the test supervisor for each test.

```elixir
defmodule MyClusterTest do
  use ExUnitCluster.Case, async: true

  test "start node and execute call", %{cluster: cluster} do
    node = ExUnitCluster.start_node(cluster)
    node_name = ExUnitCluster.call(cluster, node, Node, :self, [])
    refute Node.self() == node_name
  end
end
```

### 2. Pre-started Shared Nodes Per Module
To start a fixed number of connected nodes for all tests in a module during `setup_all`:

```elixir
defmodule MyModuleClusterTest do
  use ExUnitCluster.Case, cluster_nodes: 2

  test "nodes are pre-started", %{cluster: cluster} do
    nodes = ExUnitCluster.get_nodes(cluster)
    assert length(nodes) == 2
  end
end
```

### 3. Manual Manager Setup
In custom setup blocks or standard `ExUnit.Case`:

```elixir
defmodule MyManualTest do
  use ExUnit.Case, async: true

  setup ctx do
    cluster = start_supervised!({ExUnitCluster.Manager, ctx})
    [cluster: cluster]
  end
end
```

## Node Operations API

- **`ExUnitCluster.start_node(cluster, opts \\ [], timeout \\ 60_000)`**
  Starts a new peer node linked to the manager.
  - Options:
    - `:applications` - List of application atoms to start on the peer node (defaults to project `:app`).
    - `:environment` - Keyword list of application env overrides, e.g. `[my_app: [key: :val]]`.
    - `:join` - Boolean (default `true`). Automatically connects the new node to existing cluster nodes.

- **`ExUnitCluster.stop_node(cluster, node, timeout \\ 5_000)`**
  Stops a specific peer node in the cluster. Returns `:ok` or `{:error, :not_found}`.

- **`ExUnitCluster.get_nodes(cluster)`**
  Returns a list of active node names (`list(node())`) in the cluster.

## RPC and Block Execution

- **`ExUnitCluster.call(cluster, node, module, function, args, timeout \\ 5_000)`**
  Executes an RPC call on the specified peer node via `:peer.call/5`.

- **`in_cluster(cluster, node, do: expressions)`**
  Macro to execute a block of expressions on `node`. Compiles an anonymous helper module on the remote node.

```elixir
in_cluster cluster, node do
  assert Node.self() == node
end
```

- **`in_cluster_env(cluster, node, do: expressions)`**
  Macro to execute a block on `node` while binding and capturing variables from the caller's local scope.

```elixir
expected = "hello"
in_cluster_env cluster, node do
  assert Application.get_env(:my_app, :key) == expected
end
```

## Best Practices & Caveats

- Always pass the ExUnit context (`ctx`) when starting `ExUnitCluster.Manager` so it can compile the test file on spawned peer nodes if needed.
- Peer nodes run on `127.0.0.1` with longnames and a randomly generated security cookie.
