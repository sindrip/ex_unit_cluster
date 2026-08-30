defmodule BytecodeShippingTest do
  use ExUnitCluster.Case, async: true

  test "peers boot without compiling the test file", %{cluster: cluster} do
    peer = ExUnitCluster.start_node(cluster, applications: [])

    started =
      ExUnitCluster.rpc(peer, fn ->
        Enum.map(Application.started_applications(), fn {app, _, _} -> app end)
      end)

    refute :ex_unit in started
    refute :mix in started

    x = 20
    assert 42 == ExUnitCluster.rpc(peer, fn -> x + x + 2 end)

    result =
      in_cluster peer do
        {Node.self(), x + 1}
      end

    assert {peer.name, 21} == result
  end
end
