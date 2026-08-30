defmodule ClusterCaseAuxTest do
  use ExUnitCluster.Case, async: true

  test "spawn nodes", %{cluster: cluster} do
    n1 = ExUnitCluster.start_node(cluster)
    n2 = ExUnitCluster.start_node(cluster)
    n3 = ExUnitCluster.start_node(cluster)

    peers = ExUnitCluster.peers(cluster)

    assert peers == [n1, n2, n3]

    res =
      Enum.flat_map(peers, fn p ->
        ExUnitCluster.call(p, Node, :list, [[:visible, :this]])
      end)

    assert length(res) == 9
    assert MapSet.size(MapSet.new(res)) == 3

    for peer <- Enum.take_random(peers, length(peers)) do
      :ok = ExUnitCluster.stop_node(peer)

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
