defmodule ClusterCaseAuxTest do
  use ExUnit.Case, async: true

  setup ctx do
    cluster = start_supervised!({ExUnitCluster.Manager, ctx})
    [cluster: cluster]
  end

  test "spawn nodes", %{cluster: cluster} do
    n1 = ExUnitCluster.start_node(cluster)
    n2 = ExUnitCluster.start_node(cluster)
    n3 = ExUnitCluster.start_node(cluster)

    nodes = ExUnitCluster.get_nodes(cluster)

    assert Enum.sort([n1, n2, n3]) == Enum.sort(nodes)

    res =
      Enum.flat_map(nodes, fn n ->
        ExUnitCluster.call(cluster, n, Node, :list, [[:visible, :this]])
      end)

    assert length(res) == 9
    assert MapSet.size(MapSet.new(res)) == 3

    for n <- Enum.take_random(nodes, length(nodes)) do
      :ok = ExUnitCluster.stop_node(cluster, n)

      nodes = ExUnitCluster.get_nodes(cluster)

      # Allow the nodedown to be propagated
      Process.sleep(100)

      res =
        Enum.flat_map(nodes, fn n ->
          ExUnitCluster.call(cluster, n, Node, :list, [[:visible, :this]])
        end)

      assert length(res) == length(nodes) ** 2
      assert MapSet.size(MapSet.new(res)) == length(nodes)
    end
  end
end
