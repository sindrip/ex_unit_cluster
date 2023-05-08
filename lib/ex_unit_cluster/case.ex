defmodule ExUnitCluster.Case do
  @moduledoc """
  Extends `ExUnit.Case` to start a new `ExUnitCluster.Manager` for each test.
  """

  use ExUnit.CaseTemplate

  using options do
    %{file: file} = __CALLER__
    use_case_cluster = options[:cluster_nodes]

    quote bind_quoted: [use_case_cluster: use_case_cluster, file: file] do
      import ExUnitCluster

      if use_case_cluster do
        setup_all ctx do
          test_file = unquote(file)
          file_ctx = Map.merge(ctx, %{file: test_file})

          cluster = start_supervised!({ExUnitCluster.Manager, file_ctx})

          no_nodes = unquote(use_case_cluster)

          for _ <- 1..no_nodes do
            ExUnitCluster.start_node(cluster)
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
