defmodule NodeName.Deeply.NestedTest do
  use ExUnitCluster.Case

  test "node name is the module's last segment", %{cluster: cluster} do
    name = Atom.to_string(ExUnitCluster.start_peer(cluster).name)
    last_segment = __MODULE__ |> Module.split() |> List.last()

    assert name =~ ~r/^#{Regex.escape(last_segment)}-\d+-\d+@/
  end
end
