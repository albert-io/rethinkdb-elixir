defmodule TableTestDB, do: use RethinkDB.Connection
defmodule TableIndexTestDB, do: use RethinkDB.Connection
defmodule TableDBTestDB, do: use RethinkDB.Connection
defmodule TableTest do
  use ExUnit.Case, async: true
  use TableTestDB
  alias RethinkDB.Record

  setup_all do
    connect
    :ok
  end
  
  @table_name "table_test_table_1"

  test "tables" do
    table_drop(@table_name) |> run
    on_exit fn ->
      table_drop(@table_name) |> run
    end
    q = table_create(@table_name)
    %Record{data: %{"tables_created" => 1}} = run q

    q = table_list
    %Record{data: tables} = run q
    assert Enum.member?(tables, @table_name)

    q = table_drop(@table_name)
    %Record{data: %{"tables_dropped" => 1}} = run q

    q = table_list
    %Record{data: tables} = run q
    assert !Enum.member?(tables, @table_name)

    q = table_create(@table_name, %{primary_key: "not_id"})
    %Record{data: result} = run q
    %{"config_changes" => [%{"new_val" => %{"primary_key" => primary_key}}]} = result
    assert primary_key == "not_id"
  end
end
defmodule TableDBTest do
  use ExUnit.Case, async: true
  use TableDBTestDB
  alias RethinkDB.Record

  setup_all do
    connect
    :ok
  end
  
  @db_name "table_db_test_db_1"
  @table_name "table_db_test_table_1"

  test "tables with specific database" do
    db_create(@db_name) |> run
    on_exit fn ->
      db_drop(@db_name) |> run
    end

    q = db(@db_name) |> table_create(@table_name)
    %Record{data: %{"tables_created" => 1}} = run q

    q = db(@db_name) |> table_list
    %Record{data: tables} = run q
    assert Enum.member?(tables, @table_name)

    q = db(@db_name) |> table_drop(@table_name)
    %Record{data: %{"tables_dropped" => 1}} = run q

    q = db(@db_name) |> table_list
    %Record{data: tables} = run q
    assert !Enum.member?(tables, @table_name)

    q = db(@db_name) |> table_create(@table_name, %{primary_key: "not_id"})
    %Record{data: result} = run q
    %{"config_changes" => [%{"new_val" => %{"primary_key" => primary_key}}]} = result
    assert primary_key == "not_id"
  end
end

defmodule TableIndexTest do
  use ExUnit.Case, async: true
  use TableIndexTestDB
  alias RethinkDB.Record

  setup_all do
    connect
    :ok
  end
  
  @table_name "table_index_test_table_1"
  setup do
    table_create(@table_name) |> run
    on_exit fn ->
      table_drop(@table_name) |> run
    end
    :ok
  end

  test "indexes" do
    %Record{data: data} = table(@table_name) |> index_create("hello") |> run
    assert data == %{"created" => 1}
    %Record{data: data} = table(@table_name) |> index_wait(["hello"]) |> run
    assert [
      %{"function" => _, "geo" => false, "index" => "hello",
        "multi" => false, "outdated" => false,"ready" => true}
      ] = data
    %Record{data: data} = table(@table_name) |> index_status(["hello"]) |> run
    assert [
      %{"function" => _, "geo" => false, "index" => "hello",
        "multi" => false, "outdated" => false,"ready" => true}
      ] = data
    %Record{data: data} = table(@table_name) |> index_list |> run
    assert data == ["hello"]
    table(@table_name) |> index_rename("hello", "goodbye") |> run
    %Record{data: data} = table(@table_name) |> index_list |> run
    assert data == ["goodbye"]
    table(@table_name) |> index_drop("goodbye") |> run
    %Record{data: data} = table(@table_name) |> index_list |> run
    assert data == []
  end
end
