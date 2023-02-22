defmodule NgrokTest do
  @moduledoc false

  use ExUnit.Case, async: true

  doctest Ngrok

  setup %{test: test} do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    {:ok, ngrok_name: Module.concat(__MODULE__, test)}
  end

  test "it stores the settings", %{ngrok_name: ngrok_name} do
    start_supervised!({Ngrok, name: ngrok_name, port: 4000})

    assert Ngrok.public_url(ngrok_name) =~ ~r/http(s)?:\/\/(.*)\.ngrok\.io/
  end

  test "it raises when it cannot connect to the Ngrok API", %{ngrok_name: ngrok_name} do
    assert {:error, error} =
             start_supervised(
               {Ngrok,
                name: ngrok_name,
                port: 4000,
                api_url: "http://localhost:0",
                sleep_between_attempts: 1}
             )

    assert {{:shutdown,
             {:failed_to_start_child, Ngrok.Settings,
              {%RuntimeError{
                 message:
                   "Unable to retrieve setting from Ngrok: Could not connect to Ngrok API on http://localhost:0, reason: :econnrefused"
               }, _}}}, _} = error
  end

  test "it raises when it cannot find the Ngrok API", %{ngrok_name: ngrok_name} do
    assert {:error, error} =
             start_supervised(
               {Ngrok,
                name: ngrok_name,
                port: 4000,
                api_url: "http://localhost:4040/not_found",
                sleep_between_attempts: 1}
             )

    assert {{:shutdown,
             {:failed_to_start_child, Ngrok.Settings,
              {%RuntimeError{
                 message:
                   "Unable to retrieve setting from Ngrok: Could not find Ngrok API on http://localhost:4040/not_found, data: %{\"details\" => %{\"path\" => \"/not_found\"}, \"msg\" => \"Not Found\", \"status_code\" => 404}"
               }, _}}}, _} = error
  end

  test "it raises when it cannot parse the Ngrok API", %{ngrok_name: ngrok_name} do
    assert {:error, error} =
             start_supervised(
               {Ngrok,
                name: ngrok_name,
                port: 4000,
                api_url: "https://github.com/",
                sleep_between_attempts: 1}
             )

    assert {{:shutdown,
             {:failed_to_start_child, Ngrok.Settings,
              {%RuntimeError{
                 message:
                   "Unable to retrieve setting from Ngrok: Could not parse data from Ngrok API, data:" <>
                     _rest
               }, _}}}, _} = error
  end
end
