defmodule CaseOptionsClusterTest do
  @cluster_nodes 3

  use ExUnitCluster.Case, async: true, cluster_nodes: @cluster_nodes

  test "cluster is spawned with expected number of nodes", %{cluster: cluster} do
    peers = ExUnitCluster.peers(cluster)
    assert length(peers) == @cluster_nodes

    names =
      Enum.map(peers, fn p ->
        in_cluster p do
          Node.self()
        end
      end)

    assert names == Enum.map(peers, & &1.name)
  end
end
