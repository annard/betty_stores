defmodule BettyStores do
  @moduledoc """
  A store that allows key-value pairs with an optional timeout to be stored and retrieved.
  Since the actual implementation can be configured, a behaviour is defined for store manipulations.
  """

  @doc """
  Stores a key, an arbitrary value and a timeout for a bucket. This timeout may be optional (in that case use
  a default value :infinity in your implementation).
  """
  @callback store(bucket:: String.t, key :: String.t, value :: term, timeout) :: :ok | {:error, String.t}

  @doc"""
  Retrieve the value for a given key in a bucket.
  """
  @callback retrieve(bucket:: String.t, key :: String.t) :: {:ok, term} | :notfound | {:error, String.t}

  @doc """
  Delete the given key in a bucket from the store.
  """
  @callback delete(bucket:: String.t, key :: String.t) :: :ok | {:error, String.t}

  @doc """
  Update the value for a given key in a bucket in the store. Returns the old value in case of success.
  """
  @callback update(bucket:: String.t, key :: String.t, new_value :: term, timeout) :: {:ok, old_value :: term} | {:error, String.t}

end
