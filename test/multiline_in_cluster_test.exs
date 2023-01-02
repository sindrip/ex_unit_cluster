# credo:disable-for-this-file
defmodule MultilineInClusterTest do
  use ExUnit.Case, async: true

  require ExUnitCluster
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
        IO.inspect("I am node: #{Node.self()}")
        IO.inspect("This is the first generated block")
        :one
      end

    assert ^res_one = :one

    res_two =
      in_cluster cluster, n2 do
        IO.inspect("I am node: #{Node.self()}")
        IO.inspect("This is the second generated block")
        :two
      end

    assert ^res_two = :two
  end
end
