defmodule Ngrok.Executable do
  @moduledoc false

  use GenServer

  require Logger

  @executable Application.compile_env(:ngrok, :executable, "ngrok")

  @type start_opts :: [
          port: Ngrok.destination_port(),
          additional_arguments: [String.t()],
          protocol: Ngrok.protocol(),
          name: GenServer.name()
        ]

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts),
    do:
      GenServer.start_link(
        __MODULE__,
        Keyword.take(opts, [:port, :additional_arguments, :protocol]),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl GenServer
  def init(opts) do
    {:ok,
     Task.async(fn ->
       Rambo.run(
         @executable,
         [
           opts |> Keyword.fetch!(:protocol) |> protocol_to_cmd(),
           opts |> Keyword.fetch!(:port) |> Integer.to_string()
           | Keyword.get(opts, :additional_arguments, [])
         ],
         log: &log/1
       )
     end)}
  end

  @spec log({target :: :stdout | :stderr, message :: String.t()}) :: :ok
  defp log({:stdout, message}), do: Logger.warn("#{__MODULE__} #{message}")
  defp log({:stderr, message}), do: Logger.warn("#{__MODULE__} #{message}")

  @spec protocol_to_cmd(protocol :: Ngrok.protocol()) :: String.t()
  defp protocol_to_cmd(protocol)
  defp protocol_to_cmd(:https), do: protocol_to_cmd(:http)
  defp protocol_to_cmd(protocol), do: Atom.to_string(protocol)
end
