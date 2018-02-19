defmodule BettyStores.BucketStoreStruct do
  defstruct timeout_to_keys: %{},
            timeout_list: [],
            bucket_name: nil,
            timer: nil,
            store_pid: nil

  @type t :: %BettyStores.BucketStoreStruct{timeout_to_keys: Map.t,
            timeout_list: List.t,
            bucket_name: String.t,
            timer: PID,
            store_pid: PID
          }
end

defmodule BettyStores.BucketStore do
  @behaviour BettyStores
  use GenServer
  require Logger

  @default_timer 100

  def start_link([], name) do
    start_link(name)
  end

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, [])
  end

  def init(bucket_name \\ "") do
    Process.flag(:trap_exit, true)
    {:ok, tref} = :timer.send_interval(@default_timer, self(), :cleanup)
    store_pid = case Registry.start_link(keys: :unique, name: __MODULE__) do
      {:ok, a_pid} -> a_pid
      {:error, {:already_started, a_pid}} -> a_pid
    end
    {:ok, %BettyStores.BucketStoreStruct{bucket_name: bucket_name, store_pid: store_pid, timer: tref}}
  end

  def handle_call({:store, key, value, timeout}, _from, state) do
    case Registry.register(__MODULE__, {state.bucket_name, key}, {value, timeout}) do
      {:ok, _} ->
        new_state = update_expiry_for_state(key, timeout, state)
        {:reply, :ok, new_state}
      {:error, err_msg} ->
        {:reply, {:error, inspect(err_msg)}, state}
    end
  end

  def handle_call({:retrieve, key}, _from, state) do
    case Registry.lookup(__MODULE__, {state.bucket_name, key}) do
      [] -> {:reply, :notfound, state}
      [{_, {value, _}}] -> {:reply, {:ok, value}, state}
      _ -> {:reply, {:error, "Invalid data found for #{key} in bucket #{state.bucket_name}"}, state}
    end
  end

  def handle_call({:delete, key}, _from, state) do
    Registry.unregister(__MODULE__, {state.bucket_name, key})
    {:reply, :ok, state}
  end

  def handle_call({:update, key, value, timeout}, _from, state) do
    # NB! The Registry.update_value/3 expects a callback function, we just want to replace any existing value
    case Registry.update_value(__MODULE__, {state.bucket_name, key}, fn(_) -> {value, timeout} end) do
      :error -> {:reply, {:error, "Could not update value for #{key} in bucket #{state.bucket_name}: does it exist?"}, state}
      {_, {old_value, _}} -> {:reply, {:ok, old_value}, state}
    end
  end

  def handle_info(:cleanup, state) do
    current_ts = timestamp_since_epoch()
    {new_tk_map, new_ts_list, remove_keys} = expired_keys(state.timeout_to_keys, state.timeout_list, current_ts, [])
    # We have to remove the keys here, but only if one hasn't been updated in the meantime!
    Enum.each(remove_keys, fn(key) ->
      case Registry.lookup(__MODULE__, {state.bucket_name, key}) do
        [] -> :ok
        [{_, {_value, timestamp}}] -> unless timestamp > current_ts, do: Registry.unregister(__MODULE__, {state.bucket_name, key})
        _ -> :ok
      end
    end)

    {:noreply, %BettyStores.BucketStoreStruct{state| timeout_to_keys: new_tk_map, timeout_list: new_ts_list}}
  end

  def terminate(reason, state) do
    Process.unlink(state.store_pid)
    Process.exit(state.store_pid, :shutdown)
    :ok
  end

  @doc """
  Updates the state with an updated list of keys per expiry timestamps, and an ordered list of expiry timestamps.
  """
  @spec update_expiry_for_state(String.t, pos_integer, BettyStores.BucketStoreStruct.t) :: BettyStores.BucketStoreStruct.t
  def update_expiry_for_state(_key, :infinity, state), do: state
  def update_expiry_for_state(key, timeout, %BettyStores.BucketStoreStruct{timeout_to_keys: tk_map, timeout_list: ts_list} = state) do
    timeout_abs = timestamp_since_epoch() + timeout
    {new_tk_map, new_ts_list} = case Map.get(tk_map, timeout_abs) do
      nil -> { # New timestamp entry, need to update both map and list of timestamps
               Map.put(tk_map, timeout_abs, [key]),
               ts_list ++ [timeout_abs] |> Enum.sort
             }
      key_list -> { # Existing timestamp entry, only update the keys
               Map.put(tk_map, timeout_abs, key_list ++ [key]),
               ts_list
             }
    end
    %BettyStores.BucketStoreStruct{state| timeout_to_keys: new_tk_map, timeout_list: new_ts_list}
  end

  @doc """
  Returns the timestamp since Unix epoch in µsec. This is used to timestamp incoming packets.
  """
  @spec timestamp_since_epoch() :: pos_integer
  def timestamp_since_epoch() do
    :erlang.system_time(:milli_seconds)
  end

  @doc """
  Goes through the list of expiry timestamps and compares them to the current time. Returns a tuple of
  updated timestamp to keys, timestamps and keys to remove.
  """
  @spec expired_keys(timestamped_keys :: Map.t, timestamps :: List.t, pos_integer, keys_to_remove :: List.t) :: {timestamped_keys :: Map.t, timestamps :: List.t, keys_to_remove :: List.t}
  def expired_keys(%{}, [], _, remove_list), do: {%{}, [], remove_list}
  def expired_keys(tk_map, [ts | remainder], current_ts, remove_list) when ts <= current_ts do
    new_remove_list = remove_list ++ Map.fetch!(tk_map, ts)
    expired_keys(Map.delete(tk_map, ts), remainder, current_ts, new_remove_list)
  end
  def expired_keys(tk_map, ts_list, _, remove_list) do
    {tk_map, ts_list, remove_list}
  end

  ### BettyStores behaviour

  def store(bucket_proc, key, value, timeout \\ :infinity) do
    GenServer.call(bucket_proc, {:store, key, value, timeout})
  end

  def retrieve(bucket_proc, key) do
    GenServer.call(bucket_proc, {:retrieve, key})
  end

  def delete(bucket_proc, key) do
    GenServer.call(bucket_proc, {:delete, key})
  end

  def update(bucket_proc, key, new_value, timeout \\ :infinity) do
    GenServer.call(bucket_proc, {:update, key, new_value, timeout})
  end

end