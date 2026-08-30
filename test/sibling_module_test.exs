defmodule SiblingHelper do
  @moduledoc false

  def double(x), do: x * 2
end

defmodule SiblingModuleTest do
  use ExUnitCluster.Case, async: true

  test "sibling modules in the test file reach the peer", %{cluster: cluster} do
    peer = ExUnitCluster.start_node(cluster)

    assert 42 == ExUnitCluster.rpc(peer, fn -> SiblingHelper.double(21) end)
  end
end
