defmodule Ngrok.Api do
  @moduledoc false

  @type error :: {:error, String.t()}
  @type successful_parse :: {:ok, map}
  @type successful_get :: {:ok, String.t()}

  @spec tunnel_settings(
          api_url :: String.t(),
          protocol :: Ngrok.protocol(),
          port :: Ngrok.destination_port()
        ) ::
          error | successful_parse
  def tunnel_settings(api_url, protocol, port) do
    with {:ok, body} <- get(api_url),
         {:ok, parsed} <- parse(body) do
      find_tunnel(parsed, protocol, port)
    end
  end

  @spec get(api_url :: String.t()) :: error | successful_get
  defp get(api_url) do
    case HTTPoison.get(api_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: _, body: body}} ->
        {:error, "Could not find Ngrok API on #{api_url}, data: #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Could not connect to Ngrok API on #{api_url}, reason: #{reason}"}
    end
  end

  @spec parse(String.t()) :: error | successful_parse
  defp parse(body) do
    case Jason.decode(body) do
      {:ok, parsed} ->
        {:ok, parsed}

      _error ->
        {:error, "Could not parse data from Ngrok API, data: #{body}"}
    end
  end

  @spec find_tunnel(map, protocol :: Ngrok.protocol(), port :: Ngrok.destination_port()) ::
          error | successful_parse
  defp find_tunnel(parsed, protocol, port) do
    tunnels = Map.fetch!(parsed, "tunnels")

    case Enum.find(tunnels, &tunnel_for_protocol(&1, protocol, port)) do
      nil ->
        {:error, "No Ngrok tunnels found for protocol: #{protocol}"}

      tunnel ->
        {:ok, tunnel}
    end
  end

  @spec tunnel_for_protocol(map, Ngrok.protocol(), Ngrok.destination_port()) :: boolean
  defp tunnel_for_protocol(tunnel, protocol, port) do
    protocol_string = Atom.to_string(protocol)

    with %{"proto" => ^protocol_string, "config" => %{"addr" => target_address}} <- tunnel,
         %URI{host: "localhost", port: ^port} <- URI.parse(target_address) do
      true
    else
      _other -> false
    end
  end
end
