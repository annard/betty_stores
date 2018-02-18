defmodule BettyStores.BucketRegistry do
  use GenServer
  require Logger

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  ## Server Callbacks

  def init(_) do
    {:ok, %{buckets: %{}, bucket_refs: %{}}}
  end

  def handle_call({:lookup, name}, _from, state) do
    {:reply, Map.fetch(state.buckets, name), state}
  end

  def handle_call({:create, name}, _from, state) do
    if Map.has_key?(state.buckets, name) do
      {:reply, :ok, state}
    else
      {:ok, bucket_pid} = BettyStores.BucketSupervisor.add_bucket(name)
      ref = Process.monitor(bucket_pid)
      {:reply, :ok, %{buckets: Map.put(state.buckets, name, bucket_pid), bucket_refs: Map.put(state.bucket_refs, ref, name)}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{buckets: bucket_map, bucket_refs: refs}) do
    {name, new_refs} = Map.pop(refs, ref)
    Logger.warn("Process down for bucket #{name}")
    {:noreply, %{buckets: Map.delete(bucket_map, name), bucket_refs: new_refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

end