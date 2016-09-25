defmodule GprocSelectTest do
  use ExUnit.Case

  @compile {:parse_transform, :ms_transform}

  @moduledoc """
  Translation of https://gist.github.com/rustyio/188032 to Elixir, and using
  `ets.fun2ms` to create the matchers.

  (Using `fun2ms` suggested by Saša Jurić https://twitter.com/sasajuric/status/779610386832162816 )
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
    matcher = :ets.fun2ms(fn x -> x end)

    assert [{:"$1", [], [:"$1"]}] == matcher

    assert [
      {{:n, :l, :key1}, self, :value1},
      {{:n, :l, :key2}, self, :value2},
      {{:n, :l, :key3}, self, :value3},
      {{:n, :l, 'list key'}, self, 'list value'},
      {{:n, :l, [:complex, :key]}, self, [:complex, :value]}
    ] == :gproc.select(matcher)
  end

  test "select by value" do
    matcher = :ets.fun2ms(fn {_, _, :value1} = x -> x end)

    assert [{{:_, :_, :value1}, [], [:"$_"]}] == matcher

    assert [
      {{:n, :l, :key1}, self, :value1},
    ] == :gproc.select(matcher)
  end

  test "match a complex key" do
    matcher = :ets.fun2ms(fn {{_, _, [:complex, _]}, _, _} = x -> x end)

    assert [{{{:_, :_, [:complex, :_]}, :_, :_}, [], [:"$_"]}] == matcher

    assert [
      {{:n, :l, [:complex, :key]}, self, [:complex, :value]}
    ] == :gproc.select(matcher)
  end

  test "using a guard to find entries with keys that are lists" do
    matcher = :ets.fun2ms(fn {{_, _, key}, _, _} = x when is_list(key) -> x end)

    assert [{{{:_, :_, :"$1"}, :_, :_}, [is_list: :"$1"], [:"$_"]}] == matcher

    assert [
      {{:n, :l, 'list key'}, self, 'list value'},
      {{:n, :l, [:complex, :key]}, self, [:complex, :value]}
    ] == :gproc.select(matcher)
  end

  test "a more complicated guard: everything that is a list longer than 5 items" do
    matcher = :ets.fun2ms(fn {{_, _, key}, _, _} = x when is_list(key) and length(key) > 5 -> x end)

    assert [{{{:_, :_, :"$1"}, :_, :_},
      [{:andalso, {:is_list, :"$1"}, {:>, {:length, :"$1"}, 5}}],
      [:"$_"]}] == matcher


    assert [
      {{:n, :l, 'list key'}, self, 'list value'},
    ] == :gproc.select(matcher)
  end

  test "just returning the stored process" do
    matcher = :ets.fun2ms(fn {_, pid, :value1} -> pid end)

    assert [{{:_, :"$1", :value1}, [], [:"$1"]}] == matcher

    assert [self] == :gproc.select(matcher)
  end
end
