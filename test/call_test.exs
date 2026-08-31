defmodule CallTest do
  use ExUnitCluster.Case

  test "a remote raise surfaces in the caller", %{cluster: cluster} do
    n1 = ExUnitCluster.start_node(cluster)

    assert_raise KeyError, fn ->
      ExUnitCluster.call(cluster, n1, Map, :fetch!, [%{}, :missing])
    end
  end

  test "an unknown node raises ArgumentError", %{cluster: cluster} do
    assert_raise ArgumentError, ~r/unknown node/, fn ->
      ExUnitCluster.call(cluster, :"nope@127.0.0.1", Kernel, :node, [])
    end
  end

  test "calls to different nodes do not serialise", %{cluster: cluster} do
    n1 = ExUnitCluster.start_node(cluster)
    n2 = ExUnitCluster.start_node(cluster)

    blocked =
      Task.async(fn ->
        ExUnitCluster.call(cluster, n1, Process, :sleep, [3_000], 10_000)
      end)

    Process.sleep(200)

    assert ExUnitCluster.call(cluster, n2, Kernel, :node, [], 1_000) == n2

    Task.shutdown(blocked, :brutal_kill)
  end
end
