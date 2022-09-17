defmodule Mix.Tasks.Eg.Gen do
  use Mix.Task

  @shortdoc """
  This task starts the whole machinery to introspect specfied PostgreSQL database
  and create function calls for found stored procedures.

  ## Usage:

  > mix eg.gen [-y]


  ## Parameters

    -y      Confirms all questions during task execution
  """

  alias EctoGen.{Database, EEx.EExGenerator}
  alias EctoGen.Path, as: EGPath
  alias EctoGen.EEx, as: EGEEx
  alias Mix.Shell.IO, as: MixIO

  def run(args) do
    MixIO.info("Running generate task")

    Application.ensure_all_started(:postgrex)

    config = EctoGen.Configuration.get_config()
    {:ok, pg_pid} = Postgrex.start_link(config.database)

    do_magic(config, pg_pid, parse_args(args))

    MixIO.info("Task finished")
  end

  defp do_magic(config, pg_pid, opts \\ []) do
    %{db_project: db_project_config} = config

    MixIO.info("Getting routines from database")

    {time, routines_with_params} =
      :timer.tc(fn ->
        Database.Helpers.get_routines_with_params_to_create(pg_pid, db_project_config)
      end)

    MixIO.info("Fetching routines took: #{inspect(time)}")

    %{
      output_module: output_module,
      output_location: output_location,
      include_sensitive_data: include_sensitive_data,
      db_config: repo_module
    } = config

    EGPath.prepare_directory_structure(output_location, opts)

    [
      fn ->
        create_context_module(
          routines_with_params,
          output_location,
          output_module,
          repo_module
        )
      end,
      fn ->
        create_routine_parser_modules(
          routines_with_params,
          output_location,
          output_module,
          include_sensitive_data
        )
      end,
      fn ->
        create_routines_results_modules(
          routines_with_params,
          output_location,
          output_module
        )
      end
    ]
    |> Enum.map(&Task.async/1)
    |> Enum.map(&Task.await/1)

    :ok
  end

  defp create_context_module(routines_with_params, output_location, module_name, repo_module) do
    MixIO.info("Generating context module")

    EGEEx.create_context_module(
      routines_with_params,
      output_location,
      module_name,
      repo_module
    )
  end

  defp create_routine_parser_modules(
         routines_with_params,
         output_location,
         module_name,
         include_sensitive_data
       ) do
    MixIO.info("Generating routines parser modules")

    EGEEx.create_context_module(
      routines_with_params,
      output_location,
      module_name,
      include_sensitive_data,
      &MixIO.info(" * creating: #{&1}")
    )
  end

  defp create_routines_results_modules(routines_with_params, output_location, module_name) do
    MixIO.info("Generating routines result items modules")

    EGEEx.create_routines_results_modules(
      routines_with_params,
      output_location,
      module_name,
      &MixIO.info(" * creating: #{&1}")
    )
  end

  def parse_args(args) do
    %{
      auto_confirm: "-y" in args
    }
  end
end
