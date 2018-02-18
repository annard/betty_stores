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
    assert :ok == RegistryStore.store("Key", "Value")
    assert :ok == RegistryStore.store("Key1", :value)
    assert :ok == RegistryStore.store("Key2", fn(x) -> 2*x end)
  end

  test "should retrieve value for a key" do
    :ok = RegistryStore.store("Key", "Value")
    assert {:ok, "Value"} == RegistryStore.retrieve("Key")
  end

  test "should not fail for non-existing key" do
    assert :notfound == RegistryStore.retrieve("Ozewiewozewiezewallakristalla")
  end

  test "should delete value for a key" do
    :ok = RegistryStore.store("Key", "Value")
    assert :ok == RegistryStore.delete("Key")
  end

  test "should not fail to delete non-existing key" do
    assert :ok == RegistryStore.delete("Ozewiewozewiezewallakristalla")
  end

  test "should update existing key" do
    RegistryStore.store("Key", "Value")
    assert {:ok, "Value"} == RegistryStore.update("Key", "NewValue")
  end

  test "should fail to update for non-existing key" do
    assert {:error, _} = RegistryStore.update("Key", "NewValue")
  end

end