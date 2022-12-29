defmodule ExUnit.Cluster.Case do
  @moduledoc """
  Extends ExUnit.Case to allow dynamic cluster creation
  """
  alias ExUnit.Cluster

  use ExUnit.CaseTemplate

  setup ctx do
    opts = [test_module: ctx.module, test_name: ctx.test]
    {:ok, cluster} = Cluster.Manager.start_link(opts)

    Map.put(ctx, :cluster, cluster)
  end
end
