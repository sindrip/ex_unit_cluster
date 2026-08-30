defmodule ExUnitCluster.Manager do
  @moduledoc """
  Documentation for `ExUnitCluster.Manager`
  """

  use GenServer

  alias ExUnitCluster.Peer

  @enforce_keys [:prefix, :peers, :cookie, :test_file, :test_module, :bytecode]
  defstruct @enforce_keys

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec start_node(pid(), keyword(), timeout()) :: Peer.t()
  def start_node(pid, opts, timeout), do: GenServer.call(pid, {:start_node, opts}, timeout)

  @spec stop_node(Peer.t(), timeout()) :: :ok | {:error, :not_found}
  def stop_node(%Peer{cluster: cluster, name: name}, timeout),
    do: GenServer.call(cluster, {:stop_node, name}, timeout)

  @spec peers(pid()) :: list(Peer.t())
  def peers(pid), do: GenServer.call(pid, :peers)

  @impl true
  def init(opts) do
    test_module = opts[:module]
    test_file = opts[:file]

    # Node names allow a narrow charset, and atoms cap at 255 bytes.
    prefix =
      [test_module, opts[:test]]
      |> Enum.reject(&is_nil/1)
      |> Enum.map_join(" ", &Atom.to_string/1)
      |> String.replace(~r/[^0-9A-Za-z_-]/, "_")
      |> String.slice(0, 100)
      |> String.to_atom()

    cookie = Base.url_encode64(:rand.bytes(40))

    state = %__MODULE__{
      prefix: prefix,
      peers: [],
      cookie: cookie,
      test_file: test_file,
      test_module: test_module,
      bytecode: shippable_bytecode(test_module, test_file)
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:peers, _from, state) do
    {:reply, state.peers, state}
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
      for %Peer{join: true, pid: peer_pid} <- state.peers do
        peer_call(peer_pid, Node, :connect, [node])
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

    peer = %Peer{name: node, pid: pid, cluster: self(), join: join}

    state = %__MODULE__{state | peers: state.peers ++ [peer]}

    {:reply, peer, state}
  end

  @impl true
  def handle_call({:stop_node, name}, _from, %__MODULE__{} = state) do
    case Enum.split_with(state.peers, &(&1.name == name)) do
      {[peer], rest} ->
        :peer.stop(peer.pid)
        {:reply, :ok, %__MODULE__{state | peers: rest}}

      {[], _} ->
        {:reply, {:error, :not_found}, state}
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

  # Shipping bytecode covers only the case module itself, so a test
  # file that defines sibling modules must keep the compile fallback or
  # the siblings never reach the peer. The transient elixir_compiler_N
  # wrappers newer compilers leave loaded share the file's source and
  # are not siblings.
  defp shippable_bytecode(test_module, test_file) do
    source = to_charlist(test_file)

    file_modules =
      for {mod, _} <- :code.all_loaded(),
          not String.starts_with?(Atom.to_string(mod), "elixir_compiler_"),
          Keyword.get(mod.module_info(:compile), :source) == source,
          do: mod

    if file_modules == [test_module] do
      :persistent_term.get({ExUnitCluster, test_module}, nil)
    end
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
