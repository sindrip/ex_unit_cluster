defmodule MultilineInClusterTest do
  use ExUnit.Case, async: true

  import ExUnitCluster

  setup ctx do
    cluster = start_supervised!({ExUnitCluster.Manager, ctx})
    [cluster: cluster]
  end

  test "in_cluster macro runs multiline code on nodes", %{cluster: cluster} do
    n1 = ExUnitCluster.start_node(cluster)
    n2 = ExUnitCluster.start_node(cluster)

    res_one =
      in_cluster cluster, n1 do
        Node.self()
      end

    res_two =
      in_cluster cluster, n2 do
        Node.self()
      end

    refute res_one == res_two
  end
end
