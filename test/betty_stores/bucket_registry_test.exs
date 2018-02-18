defmodule BettyStores.BucketRegistryTest do
  use ExUnit.Case
  alias BettyStores.BucketRegistry
  alias BettyStores.BucketStore

  setup do
    registry = start_supervised!(BettyStores.BucketRegistry)
    %{registry: registry}
  end

  test "create buckets", %{registry: registry} do
    assert BucketRegistry.lookup(registry, "betty") == :error

    BucketRegistry.create(registry, "betty")
    assert {:ok, bucket} = BucketRegistry.lookup(registry, "betty")

    :ok = BucketStore.store(bucket, "Key", "Value")
    assert {:ok, "Value"} = BucketStore.retrieve(bucket, "Key")
  end

  test "removes bucket on stop", %{registry: registry} do
    BucketRegistry.create(registry, "betty")
    {:ok, bucket} = BucketRegistry.lookup(registry, "betty")

    # Stop the bucket with non-normal reason
    GenServer.stop(bucket)
    assert BucketRegistry.lookup(registry, "betty") == :error
  end

  test "removes bucket on crash", %{registry: registry} do
    BucketRegistry.create(registry, "betty")
    {:ok, bucket} = BucketRegistry.lookup(registry, "betty")

    # Stop the bucket with non-normal reason
    GenServer.stop(bucket, :shutdown)
    assert BucketRegistry.lookup(registry, "betty") == :error
  end

end