defmodule PlugCors.Mixfile do
  use Mix.Project

  def project do
    [ app: :plug_cors,
      version: "0.3.0",
      elixir: "~> 1.0.0",
      description: description,
      package: package,
      deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:plug, ">= 0.7.0"}, {:cowboy, "~> 1.0.0"}]
  end

  defp description do
    """
    CORS Plug Middleware
    """
  end

  defp package do
    [
     files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
     contributors: ["Bryan Joseph"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/bryanjos/plug_cors"}
    ]
  end
end
