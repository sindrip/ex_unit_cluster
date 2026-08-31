defmodule ExUnitCluster.Peer do
  @moduledoc """
  Handle for a node started with `ExUnitCluster.start_peer/3`.

  `name` is the node, `pid` is the `:peer` control process, `cluster`
  is the cluster that started the node, and `join` records whether the
  node takes part in automatic joining.
  """

  @enforce_keys [:name, :pid, :cluster, :join]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          name: node(),
          pid: pid(),
          cluster: pid(),
          join: boolean()
        }
end
