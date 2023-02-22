defmodule Ngrok.Settings do
  @moduledoc false

  use Agent

  require Logger

  @type start_opts :: [
          protocol: Ngrok.protocol(),
          port: Ngrok.destination_port(),
          sleep_between_attempts: timeout(),
          api_url: String.t(),
          name: Agent.name()
        ]

  @spec start_link(opts :: Keyword.t()) :: Agent.on_start()
  def start_link(opts) do
    Agent.start_link(
      fn ->
        opts
        |> Keyword.take([:port, :protocol, :api_url, :sleep_between_attempts])
        |> fetch_and_announce_settings()
      end,
      name: Keyword.get(opts, :name, __MODULE__)
    )
  end

  @doc """
  Retrieves a setting by name from the Ngrok tunnel

  - [List of available settings](https://ngrok.com/docs#list-tunnels)

  ## Example

  Get the public URL of the Ngrok tunnel

      Ngrok.Settings.get("public_url")
  """
  @spec get(name :: Agent.name(), String.t()) :: String.t() | map | nil
  def get(name \\ __MODULE__, field_name), do: Agent.get(name, &Map.get(&1, field_name))

  @spec fetch_and_announce_settings(start_opts()) :: map
  defp fetch_and_announce_settings(opts) do
    opts
    |> tunnel_settings()
    |> Kernel.tap(&announce/1)
  end

  @spec tunnel_settings(start_opts()) :: map
  defp tunnel_settings(opts), do: tunnel_settings(opts, 0, "")

  @spec tunnel_settings(start_opts(), non_neg_integer(), String.t()) :: map
  defp tunnel_settings(opts, total_attempts, error_message)

  defp tunnel_settings(_opts, 20, error_message),
    do: raise("Unable to retrieve setting from Ngrok: #{error_message}")

  defp tunnel_settings(opts, total_attempts, _error_message) do
    Process.sleep(total_attempts * Keyword.fetch!(opts, :sleep_between_attempts))

    case Ngrok.Api.tunnel_settings(
           Keyword.fetch!(opts, :api_url),
           Keyword.fetch!(opts, :protocol),
           Keyword.fetch!(opts, :port)
         ) do
      {:ok, settings} ->
        settings

      {:error, message} ->
        tunnel_settings(opts, total_attempts + 1, message)
    end
  end

  @spec announce(map) :: :ok
  defp announce(settings) do
    Logger.info("ngrok: Ngrok tunnel available at #{settings["public_url"]}")
  end
end
