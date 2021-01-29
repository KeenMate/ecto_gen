defmodule Mix.Tasks.Eg.Gen do
  use Mix.Task

  require Logger

  def run(_) do
    Logger.info("Running generate task")

    Mix.Task.run("app.start")
  end
end
