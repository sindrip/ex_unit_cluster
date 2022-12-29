defmodule ExUnit.Cluster do
  @moduledoc """
  Documentation for `ExUnit.Cluster`
  """
  alias ExUnit.Cluster

  @spec spawn_node(cluster :: pid()) :: node()
  defdelegate spawn_node(pid), to: Cluster.Manager

  @spec get_nodes(pid :: pid()) :: list(node())
  defdelegate get_nodes(pid), to: Cluster.Manager

  @spec call(pid(), node(), module(), atom(), list(term())) :: term()
  defdelegate call(pid, node, module, function, args), to: Cluster.Manager
end
