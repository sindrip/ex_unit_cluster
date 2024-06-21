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

  test "in_cluster_env macro inherits environment variables of caller", %{cluster: cluster} do
    n1 = ExUnitCluster.start_node(cluster)

    caller_variable = "expected"

    result =
      in_cluster_env cluster, n1 do
        caller_variable
      end

    assert caller_variable == result
  end
end
