defmodule ExUnitCluster do
  @external_resource "README.md"
  @moduledoc File.read!("README.md")
             |> String.split("<!-- README START -->")
             |> Enum.at(1)
             |> String.split("<!-- README END -->")
             |> List.first()

  alias ExUnitCluster.Peer

  @spec start_peer(cluster :: pid(), opts :: keyword(), timeout :: timeout()) :: Peer.t()
  def start_peer(cluster, opts \\ [], timeout \\ 60_000),
    do: GenServer.call(cluster, {:start_peer, opts}, timeout)

  @spec stop_peer(peer :: Peer.t(), timeout :: timeout()) :: :ok | {:error, :not_found}
  def stop_peer(%Peer{} = peer, timeout \\ 5_000),
    do: GenServer.call(peer.cluster, {:stop_peer, peer}, timeout)

  @spec peers(cluster :: pid()) :: [Peer.t()]
  def peers(cluster), do: GenServer.call(cluster, :peers)

  @spec call(peer :: Peer.t(), module(), atom(), list(term()), timeout()) :: term()
  def call(%Peer{pid: pid}, module, function, args, timeout \\ 5_000),
    do: :peer.call(pid, module, function, args, timeout)

  @doc """
  Execute multiline code blocks on a specific node.

  The block runs as an anonymous function, so variables from the
  caller scope are available inside it.
  """
  defmacro in_cluster(peer, do: expressions) do
    __register_bytecode_capture__(__CALLER__.module)

    quote do
      ExUnitCluster.call(unquote(peer), :erlang, :apply, [fn -> unquote(expressions) end, []])
    end
  end

  @doc false
  def __register_bytecode_capture__(nil), do: :ok

  def __register_bytecode_capture__(module) do
    unless Module.get_attribute(module, :ex_unit_cluster_capture?) do
      Module.put_attribute(module, :ex_unit_cluster_capture?, true)
      Module.put_attribute(module, :after_compile, {ExUnitCluster, :__capture_bytecode__})
      :persistent_term.put({ExUnitCluster, :expects, module}, true)
    end

    :ok
  end

  @doc false
  def __capture_bytecode__(env, bytecode) do
    :persistent_term.put({ExUnitCluster, env.module}, bytecode)
  end
end
