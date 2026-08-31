defmodule CallTest do
  use ExUnitCluster.Case

  test "a remote raise surfaces in the caller", %{cluster: cluster} do
    p1 = ExUnitCluster.start_peer(cluster)

    assert_raise KeyError, fn ->
      ExUnitCluster.call(p1, Map, :fetch!, [%{}, :missing])
    end
  end

  test "a stale handle exits with noproc", %{cluster: cluster} do
    p1 = ExUnitCluster.start_peer(cluster)
    :ok = ExUnitCluster.stop_peer(p1)

    assert {:noproc, _} = catch_exit(ExUnitCluster.call(p1, Kernel, :node, []))
    assert {:error, :not_found} = ExUnitCluster.stop_peer(p1)
  end

  test "calls to different nodes do not serialise", %{cluster: cluster} do
    p1 = ExUnitCluster.start_peer(cluster)
    p2 = ExUnitCluster.start_peer(cluster)

    blocked =
      Task.async(fn ->
        ExUnitCluster.call(p1, Process, :sleep, [3_000], 10_000)
      end)

    Process.sleep(200)

    assert ExUnitCluster.call(p2, Kernel, :node, [], 1_000) == p2.name

    Task.shutdown(blocked, :brutal_kill)
  end
end
