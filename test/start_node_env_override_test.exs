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
      %{cluster: cluster, node1: node1} = ctx

      node1_env = ExUnitCluster.call(cluster, node1, Application, :get_all_env, [@app])

      assert 777 == Keyword.get(node1_env, :key_a)
      assert @key_b_original == Keyword.get(node1_env, :key_b)
    end

    test "application env is unchanged for nodes not using option", ctx do
      %{cluster: cluster, node2: node2} = ctx

      node2_env = ExUnitCluster.call(cluster, node2, Application, :get_all_env, [@app])

      assert @key_a_original == Keyword.get(node2_env, :key_a)
      assert @key_b_original == Keyword.get(node2_env, :key_b)
    end
  end

  defp start_nodes(%{cluster: cluster}) do
    node1 = ExUnitCluster.start_node(cluster, environment: [{@app, [key_a: 777]}])
    node2 = ExUnitCluster.start_node(cluster)

    [node1: node1, node2: node2]
  end
end
