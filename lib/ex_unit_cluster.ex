defmodule ExUnitCluster do
  @external_resource "README.md"
  @moduledoc File.read!("README.md")
             |> String.split("<!-- README START -->")
             |> Enum.at(1)
             |> String.split("<!-- README END -->")
             |> List.first()

  alias ExUnitCluster.Manager

  @spec start_node(cluster :: pid(), opts :: keyword(), timeout :: timeout()) :: node()
  defdelegate start_node(pid, opts \\ [], timeout \\ 60_000), to: Manager

  @spec stop_node(cluster :: pid(), node :: node(), timeout :: timeout()) ::
          :ok | {:error, :not_found}
  defdelegate stop_node(pid, node, timeout \\ 5_000), to: Manager

  @spec get_nodes(pid :: pid()) :: list(node())
  defdelegate get_nodes(pid), to: Manager

  @spec call(pid(), node(), module(), atom(), list(term()), timeout()) :: term()
  defdelegate call(pid, node, module, function, args, timeout \\ 5_000), to: Manager

  @doc """
  Run an anonymous function on a specific node.

  Variables the function captures travel with it, and remote failures —
  including failing assertions — raise in the calling process.
  """
  @spec rpc(cluster :: pid(), node :: node(), fun :: (... -> term()), timeout :: timeout()) ::
          term()
  defdelegate rpc(pid, node, fun, timeout \\ 5_000), to: Manager

  @doc """
  Execute multiline code blocks on a specific node.

  The block runs as an anonymous function, so variables from the
  caller scope are available inside it.
  """
  defmacro in_cluster(cluster, node, do: expressions) do
    quote do
      ExUnitCluster.rpc(unquote(cluster), unquote(node), fn -> unquote(expressions) end)
    end
  end

  @doc """
  Same as `in_cluster/3`, which now also captures variables from the
  caller scope. Kept for compatibility.
  """
  defmacro in_cluster_env(cluster, node, do: expressions) do
    quote do
      ExUnitCluster.rpc(unquote(cluster), unquote(node), fn -> unquote(expressions) end)
    end
  end
end
