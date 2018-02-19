defmodule BettyStores.BucketSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # Start a Bucket process and add it to supervision
  def add_bucket(name) do
    child_spec = {BettyStores.BucketStore, {name}}
    {:ok, state} = DynamicSupervisor.start_child(__MODULE__, child_spec)
    {:ok, state}
  end

  # Terminate a Bucket process and remove it from supervision
  def remove_bucket(bucket_pid) do
    DynamicSupervisor.terminate_child(__MODULE__, bucket_pid)
  end

  # Nice utility method to check which processes are under supervision
  def children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  # Nice utility method to check which processes are under supervision
  def count_children do
    DynamicSupervisor.count_children(__MODULE__)
  end
end