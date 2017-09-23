defmodule MeteoxServer.Worker do
  use GenServer

  # Client API
  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def get_temperature(pid, location) do
    GenServer.call(pid, {:location, location})
  end

  def get_stats(pid) do
    GenServer.call(pid, :get_stats)
  end

  def reset_stats(pid) do
    GenServer.cast(pid, :reset_stats)
  end

  # Server Callbacks
  def init(opts) do
    {:ok, Map.get(opts, :initial_state, %{})}
  end

  def handle_call({:location, location}, _from, stats) do
    case temperature_of(location) do
      {:ok, temp} ->
        new_stats = update_stats(stats, location)
        {:reply, "#{location}: #{temp}°C", new_stats}
      {:error, error_message} ->
        {:reply, "Error: #{error_message}", stats}
    end
  end
  def handle_call(:get_stats, _from, stats) do
    {:reply, stats, stats}
  end

  def handle_cast(:reset_stats, stats) do
    {:noreply, %{}}
  end

  def handle_info(msg, state) do

  end

  def terminate(reason, state) do

  end

  # Helper Functions
  def temperature_of(location) do
    response = location
    |> url_of
    |> HTTPoison.get
    |> parse_response
  end

  def url_of(location) do
    location
    |> URI.encode
    |> fn location ->
      "api.openweathermap.org/data/2.5/weather?q=#{location}&APPID=#{apikey()}"
       end.()
  end

  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> JSON.decode!
    |> compute_weather
  end
  def parse_response({:ok, %HTTPoison.Response{status_code: 404}}), do: {:error, "Location not found"}
  def parse_response(_), do: {:error, "Something went wong"}

  def compute_weather(payload) do
    payload
    |> get_in([Access.key!("main"), Access.key!("temp")])
    |> fn temp -> temp - 273.15 end.()
    |> Float.ceil(2)
    |> (&({:ok, &1})).()
  end

  defp apikey do
    "261b68a7edde1fdb47ae3c8201b991a3"
  end

  defp update_stats(stats, location) do
    case Map.has_key?(stats, location) do
      true -> Map.update!(stats, location, &(&1 + 1))
      false -> Map.put_new(stats, location, 1)
    end
  end
end
