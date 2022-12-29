defmodule ExUnit.Cluster.Case do
  @moduledoc """
  Extends ExUnit.Case to allow dynamic cluster creation
  """
  alias ExUnit.Cluster

  use ExUnit.CaseTemplate

  setup ctx do
    cluster_config = Cluster.Config.new(ctx)
    Map.put(ctx, :cluster_config, cluster_config)
  end
end
