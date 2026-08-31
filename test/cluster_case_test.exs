defmodule ClusterCaseTest do
  use ExUnit.Case, async: true
  doctest ExUnitCluster

  setup ctx do
    cluster = start_supervised!({ExUnitCluster.Manager, ctx})
    [cluster: cluster]
  end

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
  end
end
