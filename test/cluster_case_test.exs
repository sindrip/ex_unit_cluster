defmodule ClusterCaseTest do
  use ExUnit.Cluster.Case, async: true

  alias ExUnit.Cluster

  test "spawn nodes", %{cluster: cluster} do
    _n1 = Cluster.Manager.spawn_node(cluster)
    _n2 = Cluster.Manager.spawn_node(cluster)
    _n3 = Cluster.Manager.spawn_node(cluster)

    nodes = Cluster.Manager.get_nodes(cluster)

    res =
      Enum.flat_map(nodes, fn n ->
        Cluster.Manager.call(cluster, n, Node, :list, [[:visible, :this]])
      end)

    assert length(res) == 9
    assert MapSet.size(MapSet.new(res)) == 3
  end
end
