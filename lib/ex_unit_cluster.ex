defmodule ExUnitCluster do
  @external_resource "README.md"
  @moduledoc File.read!("README.md")
             |> String.split("<!-- README START -->")
             |> Enum.at(1)
             |> String.split("<!-- README END -->")
             |> List.first()

  alias ExUnitCluster.Manager
  alias ExUnitCluster.Peer

  @doc """
  Start a node in the cluster, returning its `ExUnitCluster.Peer` handle.
  """
  @spec start_node(cluster :: pid(), opts :: keyword(), timeout :: timeout()) :: Peer.t()
  defdelegate start_node(pid, opts \\ [], timeout \\ 60_000), to: Manager

  @spec stop_node(peer :: Peer.t(), timeout :: timeout()) :: :ok | {:error, :not_found}
  defdelegate stop_node(peer, timeout \\ 5_000), to: Manager

  @doc """
  List the cluster's peers in the order they were started.
  """
  @spec peers(cluster :: pid()) :: list(Peer.t())
  defdelegate peers(pid), to: Manager

  @spec call(peer :: Peer.t(), module(), atom(), list(term()), timeout :: timeout()) :: term()
  defdelegate call(peer, module, function, args, timeout \\ 5_000), to: Peer

  @doc """
  Run an anonymous function on a specific node.

  Variables the function captures travel with it, and remote failures —
  including failing assertions — raise in the calling process.
  """
  # The precise fun type is arity zero, but neither spelling of it
  # survives mix format on both sides of Elixir 1.15: old formatters
  # rewrite (-> term()) and new ones rewrite (() -> term()).
  @spec rpc(peer :: Peer.t(), fun :: (... -> term()), timeout :: timeout()) :: term()
  defdelegate rpc(peer, fun, timeout \\ 5_000), to: Peer

  @doc """
  Execute multiline code blocks on a specific node.

  The block runs as an anonymous function, so variables from the
  caller scope are available inside it.
  """
  defmacro in_cluster(peer, do: expressions) do
    quote do
      ExUnitCluster.rpc(unquote(peer), fn -> unquote(expressions) end)
    end
  end
end
