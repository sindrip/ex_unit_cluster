defmodule ClusterCaseTest do
  use ExUnit.Cluster.Case, async: true

  alias ExUnit.Cluster

  test "spawn nodes", %{cluster: cluster} do
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
