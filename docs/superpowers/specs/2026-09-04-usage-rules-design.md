# Design Spec: Add `usage_rules` Support to `ex_unit_cluster`

**Date:** 2026-09-04  
**Topic:** Package-level `usage_rules.md` support for `ex_unit_cluster`  
**Approach:** Approach B (Package-Only `usage-rules.md`)

---

## 1. Overview

`usage_rules` is a convention and tool ecosystem in Elixir (by Zach Daniel and Ash Framework contributors) that provides LLMs/AI agents with clear, concise, and structured rules on how to properly use dependencies.

This design adds `usage_rules` support for `ex_unit_cluster` by providing a root `usage-rules.md` file and adding it to Hex package assets via `mix.exs`.

---

## 2. Changes & Deliverables

### A. `usage-rules.md` (Root File)
Create `usage-rules.md` in the repository root containing concise instructions and pattern rules for AI agents working with `ExUnitCluster`.

#### Content Sections:
1. **Overview & Requirements**:
   - `ExUnitCluster` manages dynamic Erlang/OTP nodes for ExUnit tests using Erlang's `:peer` module (requires OTP 25+).
2. **Test Setup Patterns**:
   - `use ExUnitCluster.Case, async: true` (per-test isolated cluster).
   - `use ExUnitCluster.Case, cluster_nodes: N` (module-level pre-started cluster nodes).
   - Manual setup: `cluster = start_supervised!({ExUnitCluster.Manager, ctx})`.
3. **Starting and Managing Nodes**:
   - `ExUnitCluster.start_node(cluster, opts \\ [])`
     - Key options: `:applications` (list of apps to start), `:environment` (override app envs), `:join` (boolean, default true).
   - `ExUnitCluster.stop_node(cluster, node)`
   - `ExUnitCluster.get_nodes(cluster)`
4. **RPC & Code Execution**:
   - `ExUnitCluster.call(cluster, node, module, function, args, timeout \\ 5000)`
   - `in_cluster(cluster, node, do: ...)` macro for executing multiline assertions/expressions.
   - `in_cluster_env(cluster, node, do: ...)` macro for executing expressions with caller variable environment binding.
5. **Guidelines & Best Practices**:
   - Use `ExUnitCluster.Case` instead of manually setting up `Manager` when possible.
   - Always pass `ctx` to `ExUnitCluster.Manager` so test module and file context are preserved.

### B. `mix.exs` Update
Update `package/0` function in `mix.exs`:
```elixir
defp package do
  [
    files: ["lib", "mix.exs", "README.md", "LICENSE", "usage-rules.md"],
    licenses: ["MIT"],
    links: %{"GitHub" => @source_url}
  ]
end
```

---

## 3. Verification & Testing

1. Run `mix test` to verify all tests pass.
2. Run `mix credo` / `mix compile` (if applicable) to ensure formatting and syntax are valid.
