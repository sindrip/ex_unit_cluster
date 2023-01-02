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

  @doc """
  Allows execution of multiline code on the nodes
  """
  defmacro in_cluster(cluster, node, do: expressions) do
    # We need a consistent random name, as this is compiled
    # on each node separately at the moment.
    module_name = :"#{:erlang.phash2(expressions)}"

    quoted =
      quote do
        def run do
          unquote(expressions)
        end
      end

    Module.create(module_name, quoted, Macro.Env.location(__ENV__))

    quote do
      ExUnitCluster.call(unquote(cluster), unquote(node), unquote(module_name), :run, [])
    end
  end
end
