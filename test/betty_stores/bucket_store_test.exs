defmodule BettyStores.BucketStoreTest do
  use ExUnit.Case
  alias BettyStores.BucketStore

  setup do
    bpid = start_supervised!(BettyStores.BucketStore)
    %{bucket: bpid}
  end

  test "should store a key", %{bucket: bpid} do
    assert :ok == BucketStore.store(bpid, "Key", "Value")
    assert :ok == BucketStore.store(bpid, "Key1", :value)
    assert :ok == BucketStore.store(bpid, "Key2", fn(x) -> 2*x end)
  end

  test "should retrieve value for a key", %{bucket: bpid} do
    :ok = BucketStore.store(bpid, "Key", "Value")
    assert {:ok, "Value"} == BucketStore.retrieve(bpid, "Key")
  end

  test "should not fail for non-existing key", %{bucket: bpid} do
    assert :notfound == BucketStore.retrieve(bpid, "Ozewiewozewiezewallakristalla")
  end

  test "should delete value for a key", %{bucket: bpid} do
    :ok = BucketStore.store(bpid, "Key", "Value")
    assert :ok == BucketStore.delete(bpid, "Key")
  end

  test "should not fail to delete non-existing key", %{bucket: bpid} do
    assert :ok == BucketStore.delete(bpid, "Ozewiewozewiezewallakristalla")
  end

  test "should update existing key", %{bucket: bpid} do
    BucketStore.store(bpid, "Key", "Value")
    assert {:ok, "Value"} == BucketStore.update(bpid, "Key", "NewValue")
    assert {:ok, "NewValue"} == BucketStore.retrieve(bpid, "Key")
  end

  test "should fail to update for non-existing key", %{bucket: bpid} do
    assert {:error, _} = BucketStore.update(bpid, "Key", "NewValue")
  end

  describe "expiring entries" do

    test "should not affect state for unspecified timeout" do
      empty_state = %BettyStores.BucketStoreStruct{}
      assert empty_state == BucketStore.update_expiry_for_state("Key", :infinity, empty_state)
    end

    test "should affect state for timeout" do
      empty_state = %BettyStores.BucketStoreStruct{}
      new_state = BucketStore.update_expiry_for_state("Key", 10, empty_state)
      assert empty_state != new_state
      assert length(new_state.timeout_list) == 1
      assert Map.keys(new_state.timeout_to_keys) == new_state.timeout_list
    end

    test "expire keys for empty state should work" do
      assert BucketStore.expired_keys(%{}, [], 1000, [:a]) == {%{}, [], [:a]}
    end

    test "expire keys should work" do
      assert BucketStore.expired_keys(%{100 => ["Key"]}, [100], 1000, []) == {%{}, [], ["Key"]}
    end

    test "should not retain key", %{bucket: bpid} do
      BucketStore.store(bpid, "Key", "Value", 10)
      Process.sleep(400)
      assert :notfound == BucketStore.retrieve(bpid, "Key")
    end

  end

end