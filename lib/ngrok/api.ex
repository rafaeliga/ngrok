defmodule Ngrok.Api do
  @moduledoc false

  @type error :: {:error, String.t()}
  @type successful_validate :: {:ok, map}
  @type successful_get :: {:ok, term()}

  @spec tunnel_settings(
          api_url :: String.t(),
          protocol :: Ngrok.protocol(),
          port :: Ngrok.destination_port()
        ) ::
          error | successful_validate
  def tunnel_settings(api_url, protocol, port) do
    with {:ok, body} <- get(api_url),
         {:ok, validated} <- validate(body) do
      find_tunnel(validated, protocol, port)
    end
  end

  @spec get(api_url :: String.t()) :: error | successful_get
  defp get(api_url) do
    case Req.get(api_url, retry: false) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: _, body: body}} ->
        {:error, "Could not find Ngrok API on #{api_url}, data: #{inspect(body)}"}

      {:error, ex} ->
        {:error, "Could not connect to Ngrok API on #{api_url}, reason: #{Exception.message(ex)}"}
    end
  end

  @spec validate(term()) :: error | successful_validate
  defp validate(body)
  defp validate(%{"tunnels" => _tunnels} = validated), do: {:ok, validated}

  defp validate(other),
    do: {:error, "Could not parse data from Ngrok API, data: #{inspect(other)}"}

  @spec find_tunnel(map, protocol :: Ngrok.protocol(), port :: Ngrok.destination_port()) ::
          error | successful_validate
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
