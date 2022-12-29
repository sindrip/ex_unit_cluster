defmodule ClusterCaseTest do
  use ExUnit.Cluster.Case, async: true

  test "spawn nodes", %{cluster_config: cluster_config} do
    cluster_config =
      cluster_config
      |> ExUnit.Cluster.spawn_node()
      |> ExUnit.Cluster.spawn_node()
      |> ExUnit.Cluster.spawn_node()

    nodes = Map.keys(ExUnit.Cluster.nodes(cluster_config))

    res =
      Enum.flat_map(nodes, fn n ->
        ExUnit.Cluster.call(cluster_config, n, Node, :list, [[:visible, :this]])
      end)

    assert length(res) == 9
    assert MapSet.size(MapSet.new(res)) == 3
  end
end
