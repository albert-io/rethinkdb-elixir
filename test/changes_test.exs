defmodule ChangesTestDB, do: use RethinkDB.Connection
defmodule ChangesTest do
  use ExUnit.Case, async: true
  alias RethinkDB.Feed
  use ChangesTestDB

  setup_all do
    socket = connect
    {:ok, %{socket: socket}}
  end

  @table_name "changes_test_table_1"
  setup do
    q = table_drop(@table_name)
    run(q)
    q = table_create(@table_name)
    run(q)
    on_exit fn ->
      table_drop(@table_name) |> run
    end
    :ok
  end

  test "first change" do
    q = table(@table_name) |> changes
    changes = %Feed{} = run(q)

    t = Task.async fn ->
      changes |> Enum.take(1)
    end
    data = %{"test" => "d"}
    table(@table_name) |> insert(data) |> run
    [h|[]] = Task.await(t)
    assert %{"new_val" => %{"test" => "d"}} = h
  end

  test "changes" do
    q = table(@table_name) |> changes
    changes = %Feed{} = run(q)
    t = Task.async fn ->
      next(changes)
    end
    data = %{"test" => "data"}
    q = table(@table_name) |> insert(data)
    res = run(q)
    expected = res.data["id"]
    changes = Task.await(t) 
    ^expected = changes.data |> hd |> Map.get("id")

    # test Enumerable
    t = Task.async fn ->
      changes |> Enum.take(5)  
    end
    1..6 |> Enum.each fn _ ->
      q = table(@table_name) |> insert(data)
      run(q)
    end
    data = Task.await(t) 
    5 = Enum.count(data)
  end
end
