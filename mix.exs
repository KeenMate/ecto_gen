defmodule EctoGen.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_gen,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      source_url: "https://github.com/KeenMate/ecto_gen"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex, :postgrex],
      mod: {EctoGen, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:postgrex, ">= 0.0.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp package do
    [
      links: %{
        "GitHub" => "https://github.com/KeenMate/ecto_gen"
      },
      licenses: ["MIT"]
    ]
  end

  defp description() do
    """
    This tool offers generating elixir functions that call PostgreSQL stored procedures and parses the result into elixir structs.
    """
  end
end
