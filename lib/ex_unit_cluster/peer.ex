defmodule ExUnitCluster.Peer do
  @moduledoc """
  Handle for a node started with `ExUnitCluster.start_node/3`.

  The handle carries everything a node-level operation needs, so it is
  passed on its own: `name` is the node, `pid` is the `:peer` control
  process, `cluster` is the manager that started the node, and `join`
  records whether the node takes part in automatic joining.
  """

  @enforce_keys [:name, :pid, :cluster, :join]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          name: node(),
          pid: pid(),
          cluster: pid(),
          join: boolean()
        }

  @spec rpc(t(), (... -> term()), timeout()) :: term()
  def rpc(%__MODULE__{pid: pid}, fun, timeout),
    do: :peer.call(pid, :erlang, :apply, [fun, []], timeout)

  @spec call(t(), module(), atom(), list(term()), timeout()) :: term()
  def call(%__MODULE__{pid: pid}, module, function, args, timeout),
    do: :peer.call(pid, module, function, args, timeout)
end
