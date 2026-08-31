defmodule ClusterCaseAuxTest do
  use ExUnitCluster.Case, async: true

  test "spawn nodes", %{cluster: cluster} do
    p1 = ExUnitCluster.start_peer(cluster)
    p2 = ExUnitCluster.start_peer(cluster)
    p3 = ExUnitCluster.start_peer(cluster)

    peers = ExUnitCluster.peers(cluster)

    assert [p1, p2, p3] == peers

    res =
      Enum.flat_map(peers, fn p ->
        ExUnitCluster.call(p, Node, :list, [[:visible, :this]])
      end)

    assert length(res) == 9
    assert MapSet.size(MapSet.new(res)) == 3

    for p <- Enum.take_random(peers, length(peers)) do
      :ok = ExUnitCluster.stop_peer(p)

      peers = ExUnitCluster.peers(cluster)

      # Allow the nodedown to be propagated
      Process.sleep(100)

      res =
        Enum.flat_map(peers, fn p ->
          ExUnitCluster.call(p, Node, :list, [[:visible, :this]])
        end)

      assert length(res) == length(peers) ** 2
      assert MapSet.size(MapSet.new(res)) == length(peers)
    end
  end
end
