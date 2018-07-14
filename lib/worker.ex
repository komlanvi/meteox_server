defmodule MeteoxServer.Worker do
  use GenServer

  @name :meteox_server
  @apikey Application.get_env(:meteox_server, __MODULE__)[:apikey]

  # Client API
  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts, [name: @name])
  end

  def get_temperature(location) do
    GenServer.call(@name, {:location, location})
  end

  def get_stats do
    GenServer.call(@name, :get_stats)
  end

  def reset_stats do
    GenServer.cast(@name, :reset_stats)
  end

  def stop, do: GenServer.cast(@name, :stop)

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

  def handle_cast(:reset_stats, _stats) do
    {:noreply, %{}}
  end
  def handle_cast(:stop, stats) do
    {:stop, :normal, stats}
  end

  def handle_info(msg, stats) do
    IO.puts "received unknow message: #{inspect msg}"
    {:noreply, stats}
  end

  def terminate(reason, stats) do
    IO.puts "Server terminate of #{inspect reason}"
    IO.puts "Last stats: #{inspect stats}"
  end

  # Helper Functi ons
  defp temperature_of(location) do
    location
    |> url_of
    |> HTTPoison.get
    |> parse_response
  end

  defp url_of(location) do
    location
    |> URI.encode
    |> fn location ->
      "api.openweathermap.org/data/2.5/weather?q=#{location}&APPID=#{apikey()}"
       end.()
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> JSON.decode!
    |> compute_weather
  end
  defp parse_response({:ok, %HTTPoison.Response{status_code: 404}}), do: {:error, "Location not found"}
  defp parse_response(_), do: {:error, "Something went wong"}

  defp compute_weather(payload) do
    payload
    |> get_in([Access.key!("main"), Access.key!("temp")])
    |> fn temp -> temp - 273.15 end.()
    |> Float.ceil(2)
    |> (&({:ok, &1})).()
  end

  defp apikey, do: @apikey

  defp update_stats(stats, location) do
    case Map.has_key?(stats, location) do
      true -> Map.update!(stats, location, &(&1 + 1))
      false -> Map.put_new(stats, location, 1)
    end
  end
end
