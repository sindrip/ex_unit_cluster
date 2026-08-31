defmodule ExUnitCluster.Case do
  @moduledoc """
  Extends `ExUnit.Case` to start a new `ExUnitCluster.Manager` for each test.
  """

  use ExUnit.CaseTemplate

  using options do
    peer_count = options[:peers]
    ExUnitCluster.__register_bytecode_capture__(__CALLER__.module)

    quote bind_quoted: [peer_count: peer_count] do
      import ExUnitCluster

      if peer_count do
        setup_all ctx do
          cluster = start_supervised!({ExUnitCluster.Manager, ctx})

          peer_count = unquote(peer_count)

          for _ <- 1..peer_count do
            ExUnitCluster.start_peer(cluster)
          end

          [cluster: cluster]
        end
      else
        setup ctx do
          cluster = start_supervised!({ExUnitCluster.Manager, ctx})
          [cluster: cluster]
        end
      end
    end
  end
end
