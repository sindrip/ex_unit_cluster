defmodule ExUnitCluster.Manager do
  @moduledoc """
  Documentation for `ExUnitCluster.Manager`
  """

  use GenServer

  defmodule NodeInfo do
    @moduledoc false

    @enforce_keys [:pid, :join]
    defstruct @enforce_keys
  end

  @enforce_keys [:prefix, :nodes, :cookie, :test_file]
  defstruct @enforce_keys

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec start_node(pid(), keyword(), timeout()) :: node()
  def start_node(pid, opts, timeout), do: GenServer.call(pid, {:start_node, opts}, timeout)

  @spec stop_node(pid(), node(), timeout()) :: :ok | {:error, :not_found}
  def stop_node(pid, node, timeout), do: GenServer.call(pid, {:stop_node, node}, timeout)

  @spec get_nodes(pid()) :: list(node())
  def get_nodes(pid), do: GenServer.call(pid, :get_nodes)

  @spec call(pid(), node(), module(), atom(), list(term()), timeout()) :: term()
  def call(pid, node, module, function, args, timeout),
    do: GenServer.call(pid, {:call, node, module, function, args}, timeout)

  @impl true
  def init(opts) do
    test_module = opts[:module]
    test_name = opts[:name]
    test_file = opts[:file]

    prefix =
      "#{Atom.to_string(test_module)} #{Atom.to_string(test_name)}"
      |> String.replace([".", " "], "_")
      |> String.to_atom()

    cookie = Base.url_encode64(:rand.bytes(40))

    state = %__MODULE__{
      prefix: prefix,
      nodes: Map.new(),
      cookie: cookie,
      test_file: test_file
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_nodes, _from, state) do
    nodes = Map.keys(state.nodes)
    {:reply, nodes, state}
  end

  @impl true
  def handle_call({:start_node, opts}, _from, state) do
    name = :peer.random_name(:"#{state.prefix}")
    applications = opts[:applications]
    join = Keyword.get(opts, :join, true)

    {:ok, pid, node} =
      :peer.start_link(%{
        name: name,
        host: ~c"127.0.0.1",
        longnames: true,
        connection: :standard_io,
        args: [
          ~c"-setcookie",
          ~c"#{state.cookie}"
        ]
      })

    if join do
      for %NodeInfo{join: node_join, pid: node_pid} <- Map.values(state.nodes) do
        if node_join do
          peer_call(node_pid, Node, :connect, [node])
        end
      end
    end

    peer_call(pid, :code, :add_paths, [:code.get_path()])

    for {app, _, _} <- Application.loaded_applications() do
      base_env = Application.get_all_env(app)

      environment =
        opts
        |> Keyword.get(:environment, [])
        |> Keyword.get(app, [])
        |> Keyword.merge(base_env, fn _, v, _ -> v end)

      for {key, val} <- environment do
        peer_call(pid, Application, :put_env, [app, key, val])
      end
    end

    peer_call(pid, Application, :ensure_all_started, [:mix])
    peer_call(pid, Mix, :env, [Mix.env()])

    # We need to start :ex_unit to be able to compile the test file
    # It would be nice to avoid doing this compilation on every node started
    peer_call(pid, Application, :ensure_all_started, [:ex_unit])
    peer_call(pid, Code, :compile_file, [state.test_file])

    if applications do
      for app <- applications do
        peer_call(pid, Application, :ensure_all_started, [app])
      end
    else
      app = Mix.Project.config()[:app]
      peer_call(pid, Application, :ensure_all_started, [app])
    end

    node_info = %NodeInfo{pid: pid, join: join}

    state = %__MODULE__{state | nodes: Map.put(state.nodes, node, node_info)}

    {:reply, node, state}
  end

  @impl true
  def handle_call({:stop_node, node}, _from, state) do
    case Map.get(state.nodes, node) do
      nil ->
        {:reply, {:error, :not_found}, state}

      %NodeInfo{pid: pid} ->
        :peer.stop(pid)
        state = %__MODULE__{state | nodes: Map.delete(state.nodes, node)}
        {:reply, :ok, state}
    end
  end

  def handle_call({:call, node, module, function, args}, _from, state) do
    %NodeInfo{pid: pid} = Map.get(state.nodes, node)
    res = peer_call(pid, module, function, args)
    {:reply, res, state}
  end

  # Top level API calls determine the timeout
  defp peer_call(dest, module, fun, args),
    do: :peer.call(dest, module, fun, args, :infinity)
end
