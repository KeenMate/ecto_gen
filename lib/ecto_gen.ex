defmodule EctoGen do
  @moduledoc """
  This module concists of logic for introspecting database and creating usable elixir code.
  """

  require Logger

  alias EctoGen.{Database, EEx.EExGenerator}

  @doc """
  Used to retrieve information from database and create elixir code based on retrieved informations
  like stored procedures.
  """
  def start(_feeling, _array) do
    config = EctoGen.Configuration.get_config()

    Logger.info("Starting ecto gen application")
    EctoGen.Application.start_link(config)

    do_magic(config)
  end

  defp do_magic(config) do
    Logger.info("Getting routines to create from database")

    %{db_project: db_project_config} = config
    routines_with_params = Database.Helpers.get_routines_with_params_to_create(db_project_config)

    %{
      output_module: output_module,
      output_location: output_location
    } = config

    sanitized_module_name = sanitize_module_name(output_module)

    ensure_output_location([output_location, Path.join(output_location, "models")])
    |> clear_output_location(output_location)

    create_context_module(routines_with_params, output_location, sanitized_module_name)

    create_routines_results_modules(routines_with_params, output_location, sanitized_module_name)

    :ok
  end

  defp create_context_module(routines_with_params, output_location, module_name) do
    Logger.info("Generating context module")

    context_module =
      EExGenerator.generate_context_module(routines_with_params, module_name: module_name)

    Logger.debug("Writing context module to output file")
    File.write(Path.join(output_location, "db_context.ex"), context_module)
  end

  defp create_routines_results_modules(routines_with_params, output_location, module_name) do
    Logger.info("Generating routines result items modules")

    EExGenerator.generate_routines_results_modules(routines_with_params, module_name)
    |> Enum.map(fn {%{schema: routine_schema, name: routine_name}, routine_result_module_code} ->
      Logger.debug("Writing routine result item module to file")

      routine_result_struct_name =
        Database.DbRoutine.get_routine_result_item_struct_name(routine_schema, routine_name)
        |> IO.iodata_to_binary()
        |> Macro.underscore()

      File.write!(
        Path.join([output_location, "models", [routine_result_struct_name, ".ex"]]),
        routine_result_module_code
      )
    end)
  end

  defp sanitize_module_name(module_name) when is_atom(module_name) do
    Atom.to_string(module_name)
  end

  defp sanitize_module_name(module_name) when is_binary(module_name), do: module_name

  defp clear_output_location(:exist, output_location) do
    # todo: log removed files to output
    output_location
    |> File.rm_rf()

    :ok
  end

  defp clear_output_location(_, _), do: nil

  defp ensure_output_location(output_locations) do
    output_locations
    |> Enum.map(fn x ->
      case File.mkdir(x) do
        :ok ->
          Logger.debug("Output location created")
          :ok

        {:error, :eexist} ->
          Logger.debug("Output location already exists")
          :exist

        {:error, reason} ->
          Logger.error(
            "Could not create directory at output location. reason: #{inspect(reason)}"
          )

          :error
      end
    end)
  end
end
