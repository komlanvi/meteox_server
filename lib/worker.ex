defmodule MeteoxServer.Worker do
  use GenServer

  # Client API
  def start_link(opts \\ %{}) do
    GenServer.start_link __MODULE__, opts, []
  end

  def get_temperature(pid, location) do

  end

  # Server Callbacks
  def init(opts) do
    {:ok, Map.get(opts, :initial_state, %{})}
  end

  def handle_call({:location, location}, _from, stats) do

  end

  def handle_cast(msg, state) do

  end

  def handle_info(msg, state) do

  end

  def terminate(reason, state) do

  end

  # Helper Functions

end
