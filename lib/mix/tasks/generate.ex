defmodule Mix.Tasks.Eg.Gen do
  use Mix.Task

  @moduledoc """
  This task starts the whole machinery to introspect specfied PostgreSQL database
  and create function calls for found stored procedures.
  """

  require Logger

  def run(_) do
    Logger.info("Running generate task")

    EctoGen.start()
  end
end
