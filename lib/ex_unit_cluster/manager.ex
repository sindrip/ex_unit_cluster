defmodule ExUnitCluster.Manager do
  @moduledoc """
  Starts, tracks, and owns the lifecycle of one cluster's peers.

  Holds no public API of its own — `ExUnitCluster` talks to it. Its pid is
  the cluster handle, and every `ExUnitCluster.Peer` carries it as
  `peer.cluster`.
  """

  use GenServer

  alias ExUnitCluster.Peer

  @enforce_keys [:prefix, :peers, :cookie, :test_module, :bytecode]
  defstruct @enforce_keys

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    test_module = opts[:module]

    prefix =
      test_module
      |> Module.split()
      |> List.last()
      |> String.to_charlist()

    cookie = Base.url_encode64(:rand.bytes(40))

    bytecode = bytecode_for(test_module)

    state = %__MODULE__{
      prefix: prefix,
      peers: [],
      cookie: cookie,
      test_module: test_module,
      bytecode: bytecode
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:peers, _from, %__MODULE__{} = state) do
    {:reply, Enum.reverse(state.peers), state}
  end

  @impl GenServer
  def handle_call({:start_peer, opts}, _from, %__MODULE__{} = state) do
    name = :peer.random_name(state.prefix)
    applications = opts[:applications]
    join = !!Keyword.get(opts, :join, true)

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
      for %Peer{join: true, pid: peer_pid} <- state.peers do
        peer_call(peer_pid, Node, :connect, [node])
      end
    end

    peer_call(pid, :code, :add_paths, [:code.get_path()])

    overrides = Keyword.get(opts, :environment, [])

    env =
      for {app, _, _} <- Application.loaded_applications() do
        {app, Keyword.merge(Application.get_all_env(app), Keyword.get(overrides, app, []))}
      end

    peer_call(pid, Application, :put_all_env, [env])

    if state.bytecode do
      peer_call(pid, :code, :load_binary, [state.test_module, ~c"ex_unit_cluster", state.bytecode])
    end

    if applications do
      for app <- applications do
        peer_call(pid, Application, :ensure_all_started, [app])
      end
    else
      app = Mix.Project.config()[:app]
      peer_call(pid, Application, :ensure_all_started, [app])
    end

    peer = %Peer{name: node, pid: pid, cluster: self(), join: join}

    {:reply, peer, %__MODULE__{state | peers: [peer | state.peers]}}
  end

  @impl GenServer
  def handle_call({:stop_peer, %Peer{} = peer}, _from, %__MODULE__{} = state) do
    if Enum.any?(state.peers, &(&1.pid == peer.pid)) do
      :peer.stop(peer.pid)
      {:reply, :ok, %__MODULE__{state | peers: Enum.reject(state.peers, &(&1.pid == peer.pid))}}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  defp bytecode_for(module) do
    if :persistent_term.get({ExUnitCluster, :expects, module}, false) do
      await_bytecode(module, 200)
    end
  end

  defp await_bytecode(module, retries) do
    case :persistent_term.get({ExUnitCluster, module}, nil) do
      nil when retries > 0 ->
        Process.sleep(5)
        await_bytecode(module, retries - 1)

      nil ->
        raise "bytecode for #{inspect(module)} was never captured"

      bytecode ->
        bytecode
    end
  end

  defp peer_call(dest, module, fun, args),
    do: :peer.call(dest, module, fun, args, :infinity)
end
