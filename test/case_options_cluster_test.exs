defmodule CaseOptionsClusterTest do
  @peer_count 3

  use ExUnitCluster.Case, async: true, peers: @peer_count

  test "cluster is spawned with expected number of nodes", %{cluster: cluster} do
    peers = ExUnitCluster.peers(cluster)
    assert length(peers) == @peer_count

    nodes =
      Enum.map(peers, fn p ->
        in_cluster p do
          Node.self()
        end
      end)

    assert nodes == Enum.map(peers, & &1.name)
  end
end
