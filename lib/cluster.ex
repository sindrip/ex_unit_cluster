defmodule ExUnit.Cluster do
  @moduledoc """
  Documentation for `ExUnit.Cluster`
  """
  alias ExUnit.Cluster

  @spec spawn_node(cluster_config :: Cluster.Config.t()) :: Cluster.Config.t()
  defdelegate spawn_node(cluster_config), to: ExUnit.Cluster.Config

  @spec nodes(cluster_config :: Cluster.Config.t()) :: list(node())
  defdelegate nodes(cluster_config), to: ExUnit.Cluster.Config
end
