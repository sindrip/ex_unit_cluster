defmodule SiblingHelper do
  @moduledoc false

  def double(x), do: x * 2
end

defmodule SiblingModuleTest do
  use ExUnitCluster.Case, async: true

  test "sibling modules in the test file are not shipped to peers", %{cluster: cluster} do
    peer = ExUnitCluster.start_peer(cluster)

    assert_raise UndefinedFunctionError, fn ->
      in_cluster peer do
        SiblingHelper.double(21)
      end
    end
  end
end
