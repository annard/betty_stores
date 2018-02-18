defmodule BettyStores.RegistryStore do
  @behaviour BettyStores

  @spec init() :: {:ok, PID} | {:error, term}
  def init() do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def store(bucket, key, value, timeout \\ :infinity) do
    case Registry.register(__MODULE__, stored_key(bucket, key), stored_value(value, timeout)) do
      {:ok, _} -> :ok
      {:error, err_msg} -> {:error, inspect(err_msg)}
    end
  end

  def retrieve(bucket, key) do
    case Registry.lookup(__MODULE__, stored_key(bucket, key)) do
      [] -> :notfound
      [{_, value_t}] -> {:ok, get_value(value_t)}
      _ -> {:error, "Invalid data found for #{key} in bucket #{bucket}"}
    end
  end

  def delete(bucket, key) do
    Registry.unregister(__MODULE__, stored_key(bucket, key))
  end

  def update(bucket, key, value, timeout \\ :infinity) do
    # NB! The Registry.update_value/3 expects a callback function, we just want to replace any existing value
    case Registry.update_value(__MODULE__, stored_key(bucket, key), fn(_) -> stored_value(value, timeout) end) do
      :error -> {:error, "Could not update value for #{key} in bucket #{bucket}: does it exist?"}
      {_, old_value_t} -> {:ok, get_value(old_value_t)}
    end
  end

  defp stored_key(bucket, key) do
    {bucket, key}
  end
  defp get_bucket({bucket, _key}), do: bucket
  defp get_key({_bucket, key}), do: key

  defp stored_value(value, timeout) do
    {value, timeout}
  end
  defp get_value({value, _timout}), do: value
  defp get_timeout({_value, timeout}), do: timeout

end