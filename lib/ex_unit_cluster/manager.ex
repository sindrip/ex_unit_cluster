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

  @enforce_keys [:prefix, :nodes, :cookie, :test_file, :test_module, :bytecode]
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
    do: :peer.call(fetch_peer_pid!(pid, node), module, function, args, timeout)

  @spec rpc(pid(), node(), (... -> term()), timeout()) :: term()
  def rpc(pid, node, fun, timeout),
    do: :peer.call(fetch_peer_pid!(pid, node), :erlang, :apply, [fun, []], timeout)

  # Calls run in the caller's process so that calls to different nodes
  # can overlap and remote errors raise where the test can see them.
  defp fetch_peer_pid!(pid, node) do
    case GenServer.call(pid, {:get_peer_pid, node}) do
      {:ok, peer} -> peer
      {:error, :not_found} -> raise ArgumentError, "unknown node #{inspect(node)}"
    end
  end

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
      test_file: test_file,
      test_module: test_module,
      bytecode: :persistent_term.get({ExUnitCluster, test_module}, nil)
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
      for %NodeInfo{join: true, pid: node_pid} <- Map.values(state.nodes) do
        peer_call(node_pid, Node, :connect, [node])
      end
    end

    peer_call(pid, :code, :add_paths, [:code.get_path()])
    copy_application_env(pid, opts)
    load_test_code(pid, state)

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
  def handle_call({:stop_node, node}, _from, %__MODULE__{} = state) do
    case Map.get(state.nodes, node) do
      nil ->
        {:reply, {:error, :not_found}, state}

      %NodeInfo{pid: pid} ->
        :peer.stop(pid)
        state = %__MODULE__{state | nodes: Map.delete(state.nodes, node)}
        {:reply, :ok, state}
    end
  end

  def handle_call({:get_peer_pid, node}, _from, state) do
    case Map.get(state.nodes, node) do
      nil -> {:reply, {:error, :not_found}, state}
      %NodeInfo{pid: pid} -> {:reply, {:ok, pid}, state}
    end
  end

  defp copy_application_env(pid, opts) do
    overrides = Keyword.get(opts, :environment, [])

    config =
      for {app, _, _} <- Application.loaded_applications() do
        env = Keyword.merge(Application.get_all_env(app), Keyword.get(overrides, app, []))
        {app, env}
      end

    peer_call(pid, Application, :put_all_env, [config])
  end

  # The case template captures the test module's bytecode after
  # compilation, so the peer loads the host's exact beam and closures
  # are guaranteed to apply. Without it the peer compiles the test file
  # itself, which needs :ex_unit running for the compile-time hooks in
  # `use ExUnit.Case`.
  defp load_test_code(pid, %__MODULE__{bytecode: nil} = state) do
    peer_call(pid, Application, :ensure_all_started, [:mix])
    peer_call(pid, Mix, :env, [Mix.env()])
    peer_call(pid, Application, :ensure_all_started, [:ex_unit])
    peer_call(pid, Code, :compile_file, [state.test_file])
  end

  defp load_test_code(pid, %__MODULE__{} = state) do
    peer_call(pid, :code, :load_binary, [state.test_module, ~c"ex_unit_cluster", state.bytecode])
  end

  # Top level API calls determine the timeout
  defp peer_call(dest, module, fun, args),
    do: :peer.call(dest, module, fun, args, :infinity)
end
