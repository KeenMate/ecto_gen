defmodule Mix.Tasks.Eg.Gen do
  use Mix.Task

  @moduledoc """
  This task starts the whole machinery to introspect specfied PostgreSQL database
  and create function calls for found stored procedures.
  """

  alias EctoGen.{Database, EEx.EExGenerator}
  alias Mix.Shell.IO, as: MixIO

  def run(_) do
    MixIO.info("Running generate task")

    Application.ensure_all_started(:postgrex)

    config = EctoGen.Configuration.get_config()
    {:ok, pg_pid} = Postgrex.start_link(config.database)

    config
    |> do_magic(pg_pid)

    MixIO.info("Task finished")
  end

  defp do_magic(config, pg_pid) do
    %{db_project: db_project_config} = config

    MixIO.info("Getting routines from database")

    {time, routines_with_params} =
      :timer.tc(fn ->
        Database.Helpers.get_routines_with_params_to_create(pg_pid, db_project_config)
        # |> Enum.map(fn {routine, params} ->
        #   {
        #     routine
        #     |> Database.DbRoutine.to_routine_with_unique_name(),
        #     params
        #   }
        # end)
      end)

    MixIO.info("Fetching routines took: #{inspect(time)}")

    %{
      output_module: output_module,
      output_location: output_location,
      include_sensitive_data: include_sensitive_data,
      db_config: repo_module
    } = config

    sanitized_module_name = sanitize_module_name(output_module)

    prepare_directory_structure(output_location)

    [
      fn ->
        create_context_module(
          routines_with_params,
          output_location,
          sanitized_module_name,
          repo_module
        )
      end,
      fn ->
        create_routine_parser_modules(
          routines_with_params,
          output_location,
          sanitized_module_name,
          include_sensitive_data
        )
      end,
      fn ->
        create_routines_results_modules(routines_with_params, output_location, sanitized_module_name)
      end
    ]
    |> Enum.map(&Task.async/1)
    |> Enum.map(&Task.await/1)

    :ok
  end

  defp create_context_module(routines_with_params, output_location, module_name, repo_module) do
    MixIO.info("Generating context module")

    context_module =
      routines_with_params
      |> EExGenerator.generate_context_module(
        module_name: module_name,
        repo_module: repo_module
      )

    MixIO.info("Creating db_context.ex")
    File.write(Path.join(output_location, "db_context.ex"), context_module)
  end

  defp create_routine_parser_modules(
         routines_with_params,
         output_location,
         module_name,
         include_sensitive_data
       ) do
    MixIO.info("Generating routines parser modules")

    EExGenerator.generate_routines_parser_modules(
      routines_with_params,
      module_name,
      include_sensitive_data
    )
    |> Enum.map(fn {routine, routine_parser_module_code} ->
      routine_parser_filename =
        routine
        |> Database.DbRoutine.to_routine_with_unique_name()
        |> Database.DbRoutine.get_routine_parser_name()
        |> IO.iodata_to_binary()
        |> Macro.underscore()

      filename = Path.join([output_location, "parsers", [routine_parser_filename, ".ex"]])

      MixIO.info(" * creating: #{filename}")

      File.write!(
        filename,
        routine_parser_module_code
      )
    end)
  end

  defp create_routines_results_modules(routines_with_params, output_location, module_name) do
    MixIO.info("Generating routines result items modules")

    EExGenerator.generate_routines_results_modules(routines_with_params, module_name)
    |> Enum.map(fn {routine, routine_result_module_code} ->
      routine_result_struct_filename =
        routine
        |> Database.DbRoutine.to_routine_with_unique_name()
        |> Database.DbRoutine.get_routine_result_item_struct_name()
        |> IO.iodata_to_binary()
        |> Macro.underscore()

      filename = Path.join([output_location, "models", [routine_result_struct_filename, ".ex"]])

      MixIO.info(" * creating: #{filename}")

      File.write!(
        filename,
        routine_result_module_code
      )
    end)
  end

  defp sanitize_module_name(module_name) when is_atom(module_name) do
    Atom.to_string(module_name)
  end

  defp sanitize_module_name(module_name) when is_binary(module_name), do: module_name

  defp prepare_directory_structure(output_location) do
    MixIO.info("Preparing directory structure")

    if MixIO.yes?(
         "Ensuring that output location: \"#{output_location}\" is clean by deleting it. \nProceed?"
       ) do
      File.rm_rf(output_location)

      [
        output_location,
        Path.join(output_location, "models"),
        Path.join(output_location, "parsers")
      ]
      |> ensure_locations()
    else
      Mix.raise("Operation aborted")
    end
  end

  defp ensure_locations(output_locations) do
    output_locations
    |> Enum.map(fn x ->
      case File.mkdir(x) do
        :ok ->
          {:ok, x}

        {:error, :eexist} ->
          {:exist, x}

        {:error, reason} ->
          Mix.raise(
            "Could not create directory at output location: #{x}. reason: #{inspect(reason)}"
          )

          {:error, x}
      end
    end)
  end
end
