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

  using do
    quote do
      # Turn node into a distributed node
      res =
        :net_kernel.start(:"exunit@127.0.0.1", %{
          name_domain: :longnames,
          # net_ticktime: 15000,
          # net_tickintensity: 100,
          # dist_listen: true,
          hidden: true
        })

      case res do
        {:ok, _} ->
          :erl_boot_server.start([{127, 0, 0, 1}])

        _ ->
          nil
      end
    end
  end
end
