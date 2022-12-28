defmodule ClusterCaseTest do
  use ExUnit.Cluster.Case, async: true

  test "spawn nodes", %{cluster_config: cluster_config} do
    cluster_config =
      cluster_config
      |> ExUnit.Cluster.spawn_node()
      |> ExUnit.Cluster.spawn_node()
      |> ExUnit.Cluster.spawn_node()

    nodes = ExUnit.Cluster.nodes(cluster_config)

    res =
      :erpc.multicall(nodes, Node, :list, [[:visible, :this]])
      |> Enum.flat_map(fn {_, y} -> y end)

    assert length(res) == 9
    assert MapSet.size(MapSet.new(res)) == 3
  end
end
