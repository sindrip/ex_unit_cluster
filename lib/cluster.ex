defmodule ExUnit.Cluster do
  @moduledoc """
  Documentation for `ExUnit.Cluster`
  """
  alias ExUnit.Cluster

  @spec spawn_node(cluster_config :: Cluster.Config.t()) :: Cluster.Config.t()
  defdelegate spawn_node(cluster_config), to: Cluster.Config

  @spec nodes(cluster_config :: Cluster.Config.t()) :: list(node())
  defdelegate nodes(cluster_config), to: Cluster.Config

  @spec call(Cluster.Config.t(), atom(), module(), atom(), list(term())) :: term()
  defdelegate call(cluster_config, node, module, function, args), to: Cluster.Config
end
