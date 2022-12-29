defmodule ExUnit.Cluster.Config do
  @moduledoc false

  @opaque t :: %__MODULE__{
            prefix: atom(),
            nodes: map()
          }

  @enforce_keys [:prefix, :nodes]
  defstruct @enforce_keys

  @spec new(map()) :: t()
  def new(%{module: module, test: test} = _ctx) do
    prefix =
      "#{Atom.to_string(module)} #{Atom.to_string(test)}"
      |> String.replace([".", " "], "_")
      |> String.to_atom()

    %__MODULE__{prefix: prefix, nodes: Map.new()}
  end

  @spec nodes(t()) :: list(node())
  def nodes(%__MODULE__{nodes: nodes}), do: nodes

  @spec call(t(), atom(), module(), atom(), list(term())) :: term()
  def call(%__MODULE__{nodes: nodes}, node, module, function, args) do
    pid = Map.get(nodes, node)
    :peer.call(pid, module, function, args)
  end

  @spec spawn_node(t()) :: t()
  def spawn_node(cluster_config) do
    name = :peer.random_name(:"#{cluster_config.prefix}")

    {:ok, pid, node} =
      :peer.start_link(%{
        name: name,
        host: '127.0.0.1',
        longnames: true,
        connection: :standard_io,
        args: [
          '-loader inet',
          '-hosts 127.0.0.1',
          '-setcookie #{:erlang.get_cookie()}'
          # '-connect_all false'
        ]
      })

    :peer.call(pid, :code, :add_paths, [:code.get_path()])
    :peer.call(pid, Application, :loaded_applications, [])

    for {app, _, _} <- Application.loaded_applications() do
      for {key, val} <- Application.get_all_env(app) do
        :peer.call(pid, Application, :put_env, [app, key, val])
      end
    end

    for node_pid <- Map.values(cluster_config.nodes) do
      :peer.call(node_pid, Node, :connect, [node])
    end

    %__MODULE__{cluster_config | nodes: Map.put(cluster_config.nodes, node, pid)}
  end
end
