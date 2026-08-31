defmodule BytecodeShippingTest do
  use ExUnitCluster.Case, async: true

  test "peers boot without compiling the test file", %{cluster: cluster} do
    peer = ExUnitCluster.start_peer(cluster, applications: [])

    started =
      in_cluster peer do
        Enum.map(Application.started_applications(), fn {app, _, _} -> app end)
      end

    refute :ex_unit in started
    refute :mix in started
  end

  test "the peer runs the host's exact beam", %{cluster: cluster} do
    peer = ExUnitCluster.start_peer(cluster)

    assert ExUnitCluster.call(peer, __MODULE__, :module_info, [:md5]) ==
             __MODULE__.module_info(:md5)
  end
end
