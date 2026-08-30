defmodule RpcTest do
  use ExUnitCluster.Case, async: true

  test "closures capture the caller environment", %{cluster: cluster} do
    peer = ExUnitCluster.start_node(cluster)
    captured = 41

    assert {peer.name, 42} == ExUnitCluster.rpc(peer, fn -> {Node.self(), captured + 1} end)
  end

  test "remote failures raise in the test process", %{cluster: cluster} do
    peer = ExUnitCluster.start_node(cluster)

    assert_raise ExUnit.AssertionError, fn ->
      ExUnitCluster.rpc(peer, fn -> assert 1 == 2 end)
    end
  end

  test "a stopped peer's handle no longer serves calls", %{cluster: cluster} do
    peer = ExUnitCluster.start_node(cluster)

    :ok = ExUnitCluster.stop_node(peer)

    assert {:error, :not_found} = ExUnitCluster.stop_node(peer)
    assert {:noproc, _} = catch_exit(ExUnitCluster.rpc(peer, fn -> :never end))
    assert ExUnitCluster.peers(cluster) == []
  end

  test "calls to different nodes run concurrently", %{cluster: cluster} do
    peer1 = ExUnitCluster.start_node(cluster)
    peer2 = ExUnitCluster.start_node(cluster)

    waiter =
      Task.async(fn ->
        ExUnitCluster.rpc(peer1, fn -> await_global(:rpc_probe, 100) end, 10_000)
      end)

    registrar =
      Task.async(fn ->
        ExUnitCluster.rpc(peer2, fn ->
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
