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
end
