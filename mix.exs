defmodule Ngrok.Mixfile do
  use Mix.Project

  @version "1.1.0"
  @source_url "https://github.com/jshmrtn/ex_ngrok"

  def project do
    [
      app: :ngrok,
      version: @version,
      elixir: "~> 1.14",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: description()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false},
      {:rambo, "~> 0.3.4"},
      {:req, "~> 0.5"}
    ]
  end

  defp description do
    """
    A wrapper around Ngrok providing a secure tunnel to
    localhost for demoing your Elixir/Phoenix web application or testing
    webhook integrations.
    """
  end

  defp docs do
    [
      source_url: @source_url,
      source_ref: "v" <> @version,
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      maintainers: ["Joshua Fleck", "Jonatan Männchen"],
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => @source_url <> "/releases",
        "Issues" => @source_url <> "/issues"
      }
    ]
  end
end
