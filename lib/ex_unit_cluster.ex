defmodule ExUnitCluster do
  @moduledoc """
  Documentation for `ExUnitCluster`
  """
  alias ExUnitCluster.Manager

  @spec start_node(cluster :: pid()) :: node()
  defdelegate start_node(pid), to: Manager

  @spec stop_node(cluster :: pid(), node :: node()) :: :ok | {:error, :not_found}
  defdelegate stop_node(pid, node), to: Manager

  @spec get_nodes(pid :: pid()) :: list(node())
  defdelegate get_nodes(pid), to: Manager

  @spec call(pid(), node(), module(), atom(), list(term())) :: term()
  defdelegate call(pid, node, module, function, args), to: Manager
end
