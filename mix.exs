defmodule GprocSelect.Mixfile do
  use Mix.Project

  def project do
    [app: :gproc_select,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :gproc]]
  end

  defp deps do
    [
      {:gproc, "~> 0.6.1" },
    ]
  end
end
