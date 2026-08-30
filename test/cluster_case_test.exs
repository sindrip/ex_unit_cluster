defmodule ClusterCaseTest do
  use ExUnit.Case, async: true
  doctest ExUnitCluster

  setup ctx do
    cluster = start_supervised!({ExUnitCluster.Manager, ctx})
    [cluster: cluster]
  end

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
  end
end
