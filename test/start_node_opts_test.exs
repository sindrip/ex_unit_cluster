defmodule StartNodeOptsTest do
  use ExUnitCluster.Case, async: true

  test "start without application", %{cluster: cluster} do
    node = ExUnitCluster.start_node(cluster, applications: [])

    node_self =
      in_cluster cluster, node do
        Node.self()
      end

    assert node_self == node
  end

  test "do not automatically join nodes together", %{cluster: cluster} do
    node1 = ExUnitCluster.start_node(cluster, join: false)
    node2 = ExUnitCluster.start_node(cluster, join: false)

    node3 = ExUnitCluster.start_node(cluster)
    node4 = ExUnitCluster.start_node(cluster, join: true)

    # Node1 and Node2 are not in the cluster
    node1_cluster_nodes =
      in_cluster cluster, node1 do
        Node.list([:visible, :hidden, :connected, :this])
      end

    node2_cluster_nodes =
      in_cluster cluster, node2 do
        Node.list([:visible, :hidden, :connected, :this])
      end

    assert length(node1_cluster_nodes) == 1
    assert length(node2_cluster_nodes) == 1
    refute node1_cluster_nodes == node2_cluster_nodes

    # Node3 and Node4 are in a cluster together
    node3_cluster_nodes =
      in_cluster cluster, node3 do
        Node.list([:visible, :hidden, :connected, :this])
      end
      |> Enum.sort()

    node4_cluster_nodes =
      in_cluster cluster, node4 do
        Node.list([:visible, :hidden, :connected, :this])
      end
      |> Enum.sort()

    assert length(node3_cluster_nodes) == 2
    assert length(node4_cluster_nodes) == 2
    assert node3_cluster_nodes == node4_cluster_nodes

    ExUnitCluster.call(cluster, node1, Node, :connect, [node3])
    ExUnitCluster.call(cluster, node1, Node, :connect, [node4])

    # We can join Node1 manually to the cluster
    node1_cluster_nodes =
      in_cluster cluster, node1 do
        Node.list([:visible, :hidden, :connected, :this])
      end
      |> Enum.sort()

    node3_cluster_nodes =
      in_cluster cluster, node3 do
        Node.list([:visible, :hidden, :connected, :this])
      end
      |> Enum.sort()

    assert length(node1_cluster_nodes) == 3
    assert length(node3_cluster_nodes) == 3
    assert node1_cluster_nodes == node3_cluster_nodes
  end
end
