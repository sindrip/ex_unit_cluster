defmodule ExUnit.Cluster do
  @moduledoc """
  Documentation for `ExUnit.Cluster`
  """
  alias ExUnit.Cluster

  @spec start_node(cluster :: pid()) :: node()
  defdelegate start_node(pid), to: Cluster.Manager

  @spec stop_node(cluster :: pid(), node :: node()) :: :ok | {:error, :not_found}
  defdelegate stop_node(pid, node), to: Cluster.Manager

  @spec get_nodes(pid :: pid()) :: list(node())
  defdelegate get_nodes(pid), to: Cluster.Manager

  @spec call(pid(), node(), module(), atom(), list(term())) :: term()
  defdelegate call(pid, node, module, function, args), to: Cluster.Manager
end
