defmodule RpcTest do
  use ExUnitCluster.Case, async: true

  test "closures capture the caller environment", %{cluster: cluster} do
    node = ExUnitCluster.start_node(cluster)
    captured = 41

    assert {node, 42} == ExUnitCluster.rpc(cluster, node, fn -> {Node.self(), captured + 1} end)
  end

  test "remote failures raise in the test process", %{cluster: cluster} do
    node = ExUnitCluster.start_node(cluster)

    assert_raise ExUnit.AssertionError, fn ->
      ExUnitCluster.rpc(cluster, node, fn -> assert 1 == 2 end)
    end
  end

  test "unknown nodes raise instead of crashing the manager", %{cluster: cluster} do
    assert_raise ArgumentError, fn ->
      ExUnitCluster.call(cluster, :"nope@127.0.0.1", Node, :self, [])
    end

    assert ExUnitCluster.get_nodes(cluster) == []
  end

  test "calls to different nodes run concurrently", %{cluster: cluster} do
    node1 = ExUnitCluster.start_node(cluster)
    node2 = ExUnitCluster.start_node(cluster)

    waiter =
      Task.async(fn ->
        ExUnitCluster.rpc(cluster, node1, fn -> await_global(:rpc_probe, 100) end, 10_000)
      end)

    registrar =
      Task.async(fn ->
        ExUnitCluster.rpc(cluster, node2, fn ->
          pid = spawn(fn -> Process.sleep(:infinity) end)
          :global.register_name(:rpc_probe, pid)
        end)
      end)

    assert Task.await(registrar) == :yes
    assert Task.await(waiter, 10_000) == :found
  end

  defp await_global(name, tries) do
    case :global.whereis_name(name) do
      :undefined when tries > 0 ->
        Process.sleep(50)
        await_global(name, tries - 1)

      :undefined ->
        :not_found

      pid when is_pid(pid) ->
        :found
    end
  end
end
