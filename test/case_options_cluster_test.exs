defmodule CaseOptionsClusterTest do
  @cluster_nodes 3

  use ExUnitCluster.Case, async: true, cluster_nodes: @cluster_nodes

  test "cluster is spawned with expected number of nodes", %{cluster: cluster} do
    expected_nodes = ExUnitCluster.get_nodes(cluster)
    assert length(expected_nodes) == @cluster_nodes

    nodes =
      Enum.map(expected_nodes, fn n ->
        in_cluster cluster, n do
          Node.self()
        end
      end)

    assert nodes == expected_nodes
  end
end
