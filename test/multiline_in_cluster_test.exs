defmodule MultilineInClusterTest do
  use ExUnit.Case, async: true

  import ExUnitCluster

  setup ctx do
    cluster = start_supervised!({ExUnitCluster.Manager, ctx})
    [cluster: cluster]
  end

  test "in_cluster macro runs multiline code on nodes", %{cluster: cluster} do
    p1 = ExUnitCluster.start_peer(cluster)
    p2 = ExUnitCluster.start_peer(cluster)

    res_one =
      in_cluster p1 do
        Node.self()
      end

    res_two =
      in_cluster p2 do
        Node.self()
      end

    refute res_one == res_two
  end

  test "in_cluster captures variables from the caller scope", %{cluster: cluster} do
    p1 = ExUnitCluster.start_peer(cluster)

    caller_variable = "expected"

    result =
      in_cluster p1 do
        caller_variable
      end

    assert caller_variable == result
  end
end
