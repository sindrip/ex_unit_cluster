defmodule ExUnitCluster.Case do
  @moduledoc """
  Extends ExUnit.Case to allow dynamic cluster creation
  """
  alias ExUnitCluster.Manager

  use ExUnit.CaseTemplate

  setup ctx do
    opts = [test_module: ctx.module, test_name: ctx.test, test_file: ctx.file]
    {:ok, cluster} = Manager.start_link(opts)

    Map.put(ctx, :cluster, cluster)
  end
end
