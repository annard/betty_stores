defmodule BettyStores.RegistryStore do
  @behaviour BettyStores

  @spec init() :: {:ok, PID} | {:error, term}
  def init() do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def store(key, value, timeout \\ :infinity) do
    case Registry.register(__MODULE__, key, {value, timeout}) do
      {:ok, _} -> :ok
      {:error, err_msg} -> {:error, inspect(err_msg)}
    end
  end

  def retrieve(key) do
    case Registry.lookup(__MODULE__, key) do
      [] -> :notfound
      [{_, {value, _}}] -> {:ok, value}
      _ -> {:error, "Multiple value found for #{key}"}
    end
  end

  def delete(key) do
    Registry.unregister(__MODULE__, key)
  end

  def update(key, value, _timeout \\ :infinity) do
    # NB! The Registry.update_value/3 expects a callback function, we just want to replace any existing value
    case Registry.update_value(__MODULE__, key, fn(_) -> value end) do
      :error -> {:error, "Could not update value for #{key}: does it exist?"}
      {_, {old_value, _}} -> {:ok, old_value}
    end
  end

end