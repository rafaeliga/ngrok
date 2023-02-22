# Ngrok Elixir Library

**Fork:** This library was forked from https://github.com/joshuafleck/ex_ngrok

A wrapper around [Ngrok](https://ngrok.com/) providing a secure tunnel to localhost for demoing your Elixir/Phoenix web application or testing webhook integrations.

Once installed, `ngrok` will manage starting and stopping Ngrok with your application and expose Ngrok's settings to your application.

## Dependencies

- **[Ngrok](https://ngrok.com/) 3.x** Install: https://ngrok.com/download

## Installation

Add `ngrok` to your `mix.exs` dependencies...

```elixir
def deps do
  [{:ngrok, "~> 1.0", only: [:dev]}]
end
```

## Configuration

The default configurations may be overridden by setting any
of the following in your `config/config.exs` file:

```elixir
config :ngrok,
  # The name / path of the Ngrok executable
  executable: "ngrok"
```

## Usage

### Start `Ngrok` in your application / supervisor

Add the following code to your application / supervisor:

```elixir
{Ngrok, port: 4000, name: MyApp.Ngrok}
```

The follwoing options are supported:

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

### Retrieving your public URL

Ngrok will create a public URL that tunnels to your development machine.
The URL will change every time Ngrok starts, but you can retrieve the URL
by running the following:

```elixir
Ngrok.public_url(MyApp.Ngrok) # => http://(.*).ngrok.io/
```
