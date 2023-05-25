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
  Execute multiline code blocks on a specific node
  """
  defmacro in_cluster(cluster, node, do: expressions) do
    # We need a consistent random name, as this is compiled
    # on each node separately at the moment.
    module_name = :"#{:erlang.phash2(expressions)}"

    quoted =
      quote do
        import ExUnit.Assertions

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
