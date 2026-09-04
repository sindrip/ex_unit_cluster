# `usage_rules` Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `usage_rules` support to `ex_unit_cluster` by creating a root `usage-rules.md` file and updating `mix.exs` package distribution files.

**Architecture:** Create `usage-rules.md` containing concise usage guidance for AI agents working with `ExUnitCluster`. Update `mix.exs` `package/0` definition to include `"usage-rules.md"` in Hex package `files`.

**Tech Stack:** Elixir, Mix, ExUnit

## Global Constraints

- Target file: `usage-rules.md` in repository root.
- `mix.exs` update: Add `"usage-rules.md"` to `files:` array in `package/0`.
- Compatibility: Elixir >= 1.15.0, Erlang/OTP >= 25.

---

### Task 1: Create `usage-rules.md`

**Files:**
- Create: `usage-rules.md`

**Interfaces:**
- Consumes: `ExUnitCluster`, `ExUnitCluster.Case`, `ExUnitCluster.Manager` APIs
- Produces: `usage-rules.md` for AI agent discovery and Hex distribution

- [ ] **Step 1: Write `usage-rules.md`**

Create `usage-rules.md` with the following content:

```markdown
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
  Macro to execute a block of expressions on `node`. Compiles a anonymous helper module on the remote node.

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
```

- [ ] **Step 2: Verify `usage-rules.md` file exists**

Run: `ls -la usage-rules.md`
Expected: `usage-rules.md` is present in the repository root.

- [ ] **Step 3: Commit `usage-rules.md`**

```bash
git add usage-rules.md
git commit -m "docs: add usage-rules.md"
```

---

### Task 2: Update `mix.exs` Package Configuration

**Files:**
- Modify: `mix.exs:41-47`

**Interfaces:**
- Consumes: `usage-rules.md`
- Produces: Hex package definition including `usage-rules.md`

- [ ] **Step 1: Update `mix.exs` `package/0`**

In `mix.exs`, update `package/0` to add `"usage-rules.md"` to `files`:

```elixir
  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", "usage-rules.md"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
```

- [ ] **Step 2: Run `mix compile` and `mix test` to verify build and test suite**

Run: `mix compile && mix test`
Expected: Compilation succeeds and all tests pass cleanly (0 failures).

- [ ] **Step 3: Commit `mix.exs` update**

```bash
git add mix.exs
git commit -m "build: include usage-rules.md in package files"
```
