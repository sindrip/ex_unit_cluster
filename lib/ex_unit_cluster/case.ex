defmodule ExUnitCluster.Case do
  @moduledoc """
  Extends `ExUnit.Case` to start a new `ExUnitCluster.Manager` for each test.
  """

  use ExUnit.CaseTemplate

  setup ctx do
    cluster = start_supervised!({ExUnitCluster.Manager, ctx})
    [cluster: cluster]
  end
end
