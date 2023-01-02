defmodule ExUnitCluster.Case do
  @moduledoc """
  Extends ExUnit.Case to allow dynamic cluster creation
  """
  alias ExUnitCluster.Manager

  use ExUnit.CaseTemplate

  setup ctx do
    {:ok, cluster} = Manager.start_link(ctx)

    Map.put(ctx, :cluster, cluster)
  end
end
