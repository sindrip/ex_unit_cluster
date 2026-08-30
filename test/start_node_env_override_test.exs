defmodule StartNodeEnvOverrideTest do
  use ExUnit.Case

  @app :ex_unit_cluster
  @key_a_original 123_456
  @key_b_original "B_VALUE"

  setup ctx do
    original_env = Application.get_all_env(@app)

    Application.put_env(@app, :key_a, @key_a_original)
    Application.put_env(@app, :key_b, @key_b_original)

    on_exit(fn ->
      original_env
      |> Enum.each(fn {key, value} -> Application.put_env(@app, key, value) end)
    end)

    cluster = start_supervised!({ExUnitCluster.Manager, ctx})

    [cluster: cluster]
  end

  describe ":environment option used with start_node/2" do
    setup [:start_nodes]

    test "application env is overriden for node using option", ctx do
      %{peer1: peer1} = ctx

      peer1_env = ExUnitCluster.call(peer1, Application, :get_all_env, [@app])

      assert 777 == Keyword.get(peer1_env, :key_a)
      assert @key_b_original == Keyword.get(peer1_env, :key_b)
    end

    test "application env is unchanged for nodes not using option", ctx do
      %{peer2: peer2} = ctx

      peer2_env = ExUnitCluster.call(peer2, Application, :get_all_env, [@app])

      assert @key_a_original == Keyword.get(peer2_env, :key_a)
      assert @key_b_original == Keyword.get(peer2_env, :key_b)
    end
  end

  defp start_nodes(%{cluster: cluster}) do
    peer1 = ExUnitCluster.start_node(cluster, environment: [{@app, [key_a: 777]}])
    peer2 = ExUnitCluster.start_node(cluster)

    [peer1: peer1, peer2: peer2]
  end
end
