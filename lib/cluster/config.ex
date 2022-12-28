defmodule ExUnit.Cluster.Config do
  @moduledoc false

  @opaque t :: %__MODULE__{}

  @enforce_keys [:prefix, :nodes]
  defstruct @enforce_keys

  @spec new(map()) :: t()
  def new(%{module: module, test: test} = _ctx) do
    prefix =
      "#{Atom.to_string(module)} #{Atom.to_string(test)}"
      |> String.replace([".", " "], "_")
      |> String.to_atom()

    %__MODULE__{prefix: prefix, nodes: []}
  end

  @spec nodes(t()) :: list(node())
  def nodes(%__MODULE__{nodes: nodes}), do: nodes

  @spec spawn_node(t()) :: t()
  def spawn_node(cluster_config) do
    name = :"#{cluster_config.prefix}-#{length(cluster_config.nodes)}"

    {:ok, _pid, node} =
      :peer.start_link(%{
        name: name,
        host: '127.0.0.1',
        args: [
          '-loader inet',
          '-hosts 127.0.0.1',
          '-setcookie #{:erlang.get_cookie()}',
          '-connect_all false'
        ]
      })

    rpc(node, :code, :add_paths, [:code.get_path()])
    rpc(node, Application, :loaded_applications, [])
    rpc(node, Application, :ensure_all_started, [:cluster_case])
    rpc(node, Application, :loaded_applications, [])

    :erpc.multicall(cluster_config.nodes, Node, :connect, [node])

    %__MODULE__{cluster_config | nodes: [node | cluster_config.nodes]}
  end

  defp rpc(node, module, func, args),
    do: :rpc.call(node, module, func, args)
end
