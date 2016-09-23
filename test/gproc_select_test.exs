defmodule GprocSelectTest do
  use ExUnit.Case
  doctest GprocSelect

  @moduledoc """
  Translation of https://gist.github.com/rustyio/188032
  """

  setup do
    :gproc.reg({:n, :l, :key1}, :value1)
    :gproc.reg({:n, :l, :key2}, :value2)
    :gproc.reg({:n, :l, :key3}, :value3)
    :gproc.reg({:n, :l, 'list key'}, 'list value')
    :gproc.reg({:n, :l, [:complex, :key]}, [:complex, :value])
    :ok
  end

  test "selecting all" do
    match_head = :"_"
    guard = []
    result = [:"$$"]
    assert [
      [{:n, :l, :key1}, self, :value1],
      [{:n, :l, :key2}, self, :value2],
      [{:n, :l, :key3}, self, :value3],
      [{:n, :l, 'list key'}, self, 'list value'],
      [{:n, :l, [:complex, :key]}, self, [:complex, :value]]
    ] == :gproc.select([{match_head, guard, result}])
  end

  test "select by value" do
    match_head = {:"_", :"_", :value1}
    guard = []
    result = [:"$$"]
    assert [
      [{:n, :l, :key1}, self, :value1],
    ] == :gproc.select([{match_head, guard, result}])
  end

  test "match a complex key" do
    key = [:complex, :"_"]
    gproc_key = {:"_", :"_", key}
    match_head = {gproc_key, :"_", :"_"}
    guard = []
    result = [:"$$"]
    assert [
      [{:n, :l, [:complex, :key]}, self, [:complex, :value]]
    ] == :gproc.select([{match_head, guard, result}])
  end

  test "using a guard to find entries with keys that are lists" do
    gproc_key = {:"_", :"_", :"$1"}
    match_head = {gproc_key, :"_", :"_"}
    guard = [{:is_list, :"$1"}]
    result = [:"$$"]
    assert [
      [{:n, :l, 'list key'}, self, 'list value'],
      [{:n, :l, [:complex, :key]}, self, [:complex, :value]]
    ] == :gproc.select([{match_head, guard, result}])
  end

  test "a more complicated guard: everything that is a list longer than 5 items" do
    gproc_key = {:"_", :"_", :"$1"}
    match_head = {gproc_key, :"_", :"_"}
    guard = [
      {:"andalso", {:is_list, :"$1"}, {:">", {:length, :"$1"}, 5}},
    ]
    result = [:"$$"]
    assert [
      [{:n, :l, 'list key'}, self, 'list value'],
    ] == :gproc.select([{match_head, guard, result}])
  end
end
