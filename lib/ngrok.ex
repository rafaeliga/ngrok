defmodule Ngrok do
  @moduledoc """
  By including this supervisor in your application, an Ngrok process will be
  started when your application starts and stopped when your application stops

  ## Options

  * `port` (`integer` / `required`) - The port to tunnel.
  * `protocol` (`atom` / default: `https`) - The protocol to tunnel.
    (`http` / `https` / `tcp` / `tls`)
  * `additional_arguments` (`[String.t()]` / default: `[]`) - Additional options
    to pass to `ngrok`.
  * `name` (Supervisor name / default: `Ngrok`) - Name of the supervisor in your
    application.
  * `api_url` (url / default: `http://localhost:4040/api/tunnels`) - The URL of
    Ngrok's API (used to retrieve its settings).
  * `sleep_between_attempts` (timeout (ms) / default: 200) - The amount of sleep
    (in ms) to put between attempts to connect to Ngrok

  ## Config

      config :ngrok,
          # The name / path of the Ngrok executable
          executable: "ngrok"
  """

  use Supervisor

  alias Ngrok.Executable
  alias Ngrok.Settings

  @type destination_port :: pos_integer()
  @type protocol :: :http | :https | :tcp | :tls
  @type strict_name :: atom() | {:global, atom()}
  @type start_opts :: [
          port: destination_port(),
          additional_arguments: [String.t()],
          protocol: protocol(),
          api_url: String.t(),
          sleep_between_attempts: timeout(),
          name: strict_name()
        ]

  @spec start_link(opts :: start_opts()) :: Supervisor.on_start()
  def start_link(opts),
    do:
      Supervisor.start_link(
        __MODULE__,
        Keyword.take(opts, [
          :port,
          :additional_arguments,
          :protocol,
          :api_url,
          :name,
          :sleep_between_attempts
        ]),
        name: Keyword.get(opts, :name, __MODULE__)
      )

  @impl Supervisor
  def init(opts),
    do:
      Supervisor.init(
        [
          {Executable, executable_config(opts)},
          {Settings, settings_config(opts)}
        ],
        strategy: :rest_for_one
      )

  @doc """
  Retrieves the public URL of the Ngrok tunnel

  ## Example

      Ngrok.public_url # => http://(.*).ngrok.io/
  """
  @spec public_url(name :: strict_name()) :: String.t()
  def public_url(name \\ __MODULE__),
    do: name |> extend_name(Settings) |> Settings.get("public_url")

  @spec executable_config(start_opts()) :: Executable.start_opts()
  defp executable_config(opts) do
    [
      port: Keyword.fetch!(opts, :port),
      additional_arguments: Keyword.get(opts, :additional_arguments, []),
      protocol: Keyword.get(opts, :protocol, :https),
      name: opts |> Keyword.get(:name, __MODULE__) |> extend_name(Executable)
    ]
  end

  @spec settings_config(start_opts()) :: Settings.start_opts()
  defp settings_config(opts) do
    [
      port: Keyword.fetch!(opts, :port),
      protocol: Keyword.get(opts, :protocol, :https),
      api_url: Keyword.get(opts, :api_url, "http://localhost:4040/api/tunnels"),
      sleep_between_attempts: Keyword.get(opts, :sleep_between_attempts, 200),
      name: opts |> Keyword.get(:name, __MODULE__) |> extend_name(Settings)
    ]
  end

  @spec extend_name(name :: strict_name(), extend :: atom()) :: strict_name()
  defp extend_name(name, extend)

  # credo:disable-for-lines:2 Credo.Check.Warning.UnsafeToAtom
  defp extend_name({:global, name}, extend) when is_atom(name),
    do: {:global, Module.concat(name, extend)}

  # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
  defp extend_name(name, extend) when is_atom(name), do: Module.concat(name, extend)
end
