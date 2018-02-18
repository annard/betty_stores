defmodule BettyStores.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    BettyStores.Supervisor.start_link(name: BettyStores.Supervisor)
  end
end
