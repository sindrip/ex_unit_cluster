defmodule StartNodeOptsTest do
  use ExUnitCluster.Case, async: true

  test "start without application", %{cluster: cluster} do
    peer = ExUnitCluster.start_peer(cluster, applications: [])

    node_self =
      in_cluster peer do
        Node.self()
      end

    assert node_self == peer.name
  end

  test "do not automatically join nodes together", %{cluster: cluster} do
    peer1 = ExUnitCluster.start_peer(cluster, join: false)
    peer2 = ExUnitCluster.start_peer(cluster, join: false)

    peer3 = ExUnitCluster.start_peer(cluster)
    peer4 = ExUnitCluster.start_peer(cluster, join: true)

    # Node1 and Node2 are not in the cluster
    peer1_visible_nodes =
      in_cluster peer1 do
        Node.list([:visible, :hidden, :connected, :this])
      end

    peer2_visible_nodes =
      in_cluster peer2 do
        Node.list([:visible, :hidden, :connected, :this])
      end

    assert length(peer1_visible_nodes) == 1
    assert length(peer2_visible_nodes) == 1
    refute peer1_visible_nodes == peer2_visible_nodes

    # Node3 and Node4 are in a cluster together
    peer3_visible_nodes =
      in_cluster peer3 do
        Node.list([:visible, :hidden, :connected, :this])
      end
      |> Enum.sort()

    peer4_visible_nodes =
      in_cluster peer4 do
        Node.list([:visible, :hidden, :connected, :this])
      end
      |> Enum.sort()

    assert length(peer3_visible_nodes) == 2
    assert length(peer4_visible_nodes) == 2
    assert peer3_visible_nodes == peer4_visible_nodes

    ExUnitCluster.call(peer1, Node, :connect, [peer3.name])
    ExUnitCluster.call(peer1, Node, :connect, [peer4.name])

    # We can join Node1 manually to the cluster
    peer1_visible_nodes =
      in_cluster peer1 do
        Node.list([:visible, :hidden, :connected, :this])
      end
      |> Enum.sort()

    peer3_visible_nodes =
      in_cluster peer3 do
        Node.list([:visible, :hidden, :connected, :this])
      end
      |> Enum.sort()

    assert length(peer1_visible_nodes) == 3
    assert length(peer3_visible_nodes) == 3
    assert peer1_visible_nodes == peer3_visible_nodes
  end
end
