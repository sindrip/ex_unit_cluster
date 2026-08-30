defmodule StartNodeOptsTest do
  use ExUnitCluster.Case, async: true

  test "start without application", %{cluster: cluster} do
    peer = ExUnitCluster.start_node(cluster, applications: [])

    node_self =
      in_cluster peer do
        Node.self()
      end

    assert node_self == peer.name
  end

  test "do not automatically join nodes together", %{cluster: cluster} do
    peer1 = ExUnitCluster.start_node(cluster, join: false)
    peer2 = ExUnitCluster.start_node(cluster, join: false)

    peer3 = ExUnitCluster.start_node(cluster)
    peer4 = ExUnitCluster.start_node(cluster, join: true)

    # Peer1 and Peer2 are not in the cluster
    peer1_cluster_nodes =
      in_cluster peer1 do
        Node.list([:visible, :hidden, :connected, :this])
      end

    peer2_cluster_nodes =
      in_cluster peer2 do
        Node.list([:visible, :hidden, :connected, :this])
      end

    assert length(peer1_cluster_nodes) == 1
    assert length(peer2_cluster_nodes) == 1
    refute peer1_cluster_nodes == peer2_cluster_nodes

    # Peer3 and Peer4 are in a cluster together
    peer3_cluster_nodes =
      in_cluster peer3 do
        Node.list([:visible, :hidden, :connected, :this])
      end
      |> Enum.sort()

    peer4_cluster_nodes =
      in_cluster peer4 do
        Node.list([:visible, :hidden, :connected, :this])
      end
      |> Enum.sort()

    assert length(peer3_cluster_nodes) == 2
    assert length(peer4_cluster_nodes) == 2
    assert peer3_cluster_nodes == peer4_cluster_nodes

    ExUnitCluster.call(peer1, Node, :connect, [peer3.name])
    ExUnitCluster.call(peer1, Node, :connect, [peer4.name])

    # We can join Peer1 manually to the cluster
    peer1_cluster_nodes =
      in_cluster peer1 do
        Node.list([:visible, :hidden, :connected, :this])
      end
      |> Enum.sort()

    peer3_cluster_nodes =
      in_cluster peer3 do
        Node.list([:visible, :hidden, :connected, :this])
      end
      |> Enum.sort()

    assert length(peer1_cluster_nodes) == 3
    assert length(peer3_cluster_nodes) == 3
    assert peer1_cluster_nodes == peer3_cluster_nodes
  end
end
