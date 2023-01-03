defmodule ExUnitCluster do
  @moduledoc """
  Helpers for writing tests on nodes in isolated clusters.

  This library relies on the [:peer](https://www.erlang.org/doc/man/peer.html)
  module which was introduced in OTP 25.

  ## Examples

  The most straightforward way to start using `ExUnitCluster` for a distributed test,
  is to start `ExUnitCluster.Manager` inside the test.

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

  If you want all tests in a module to use a cluster you can start `ExUnitCluster.Manager` in
  `ExUnit.Callbacks.setup/1`.

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

  Which is exactly what `ExUnitCluster.Case` does

      defmodule ClusterTest do
        use ExUnitCluster.Case, async: true

        test "start node in test", %{cluster: cluster} do
          node = ExUnitCluster.start_node(cluster)

          node_name = ExUnitCluster.call(cluster, node, Node, :self, [])
          refute Node.self() == node_name
        end
      end

  """
  alias ExUnitCluster.Manager

  @spec start_node(cluster :: pid()) :: node()
  defdelegate start_node(pid), to: Manager

  @spec stop_node(cluster :: pid(), node :: node()) :: :ok | {:error, :not_found}
  defdelegate stop_node(pid, node), to: Manager

  @spec get_nodes(pid :: pid()) :: list(node())
  defdelegate get_nodes(pid), to: Manager

  @spec call(pid(), node(), module(), atom(), list(term())) :: term()
  defdelegate call(pid, node, module, function, args), to: Manager

  @doc """
  Execute multiline code blocks on a specific node
  """
  defmacro in_cluster(cluster, node, do: expressions) do
    # We need a consistent random name, as this is compiled
    # on each node separately at the moment.
    module_name = :"#{:erlang.phash2(expressions)}"

    quoted =
      quote do
        import ExUnit.Assertions

        def run do
          unquote(expressions)
        end
      end

    Module.create(module_name, quoted, Macro.Env.location(__ENV__))

    quote do
      ExUnitCluster.call(unquote(cluster), unquote(node), unquote(module_name), :run, [])
    end
  end
end
