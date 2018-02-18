defmodule RegistryStoreTest do
  use ExUnit.Case
  alias BettyStores.RegistryStore

  setup do
    {:ok, rpid} = RegistryStore.init()
    on_exit fn ->
      Process.unlink(rpid)
      Process.exit(rpid, :shutdown)
    end
    :ok
  end

  test "should store a key" do
    assert :ok == RegistryStore.store("Bucket", "Key", "Value")
    assert :ok == RegistryStore.store("Bucket", "Key1", :value)
    assert :ok == RegistryStore.store("Bucket", "Key2", fn(x) -> 2*x end)
  end

  test "should store identical keys in separate buckets" do
    assert :ok == RegistryStore.store("Bucket", "Key", "Value")
    assert :ok == RegistryStore.store("Bucket2", "Key", :value)
  end

  test "should retrieve value for a key" do
    :ok = RegistryStore.store("Bucket", "Key", "Value")
    assert {:ok, "Value"} == RegistryStore.retrieve("Bucket", "Key")
  end

  test "should not fail for non-existing key" do
    assert :notfound == RegistryStore.retrieve("bucket", "Ozewiewozewiezewallakristalla")
  end

  test "should delete value for a key" do
    :ok = RegistryStore.store("Bucket", "Key", "Value")
    assert :ok == RegistryStore.delete("Bucket", "Key")
  end

  test "should not fail to delete non-existing key" do
    assert :ok == RegistryStore.delete("Bucket", "Ozewiewozewiezewallakristalla")
  end

  test "should update existing key" do
    RegistryStore.store("Bucket", "Key", "Value")
    assert {:ok, "Value"} == RegistryStore.update("Bucket", "Key", "NewValue")
    assert {:ok, "NewValue"} == RegistryStore.retrieve("Bucket", "Key")
  end

  test "should fail to update for non-existing key" do
    assert {:error, _} = RegistryStore.update("Bucket", "Key", "NewValue")
  end

end