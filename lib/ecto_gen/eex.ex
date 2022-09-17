defmodule EctoGen.EEx do

  alias EctoGen.{Database, EEx.EExGenerator}

  def create_context_module(routines_with_params, output_location, module_name, repo_module) do
    context_module =
      routines_with_params
      |> EExGenerator.generate_context_module(
        module_name: module_name,
        repo_module: repo_module
      )

    File.write(Path.join(output_location, "db_context.ex"), context_module)
  end

  def create_routine_parser_modules(
         routines_with_params,
         output_location,
         module_name,
         include_sensitive_data,
         before_write_file \\ nil
       ) do

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

      if is_function(before_write_file) do
        before_write_file.(filename)
      end
      File.write!(
        filename,
        routine_parser_module_code
      )
    end)
  end

  def create_routines_results_modules(
    routines_with_params,
    output_location,
    module_name,
    before_write_file \\ nil
  ) do

    EExGenerator.generate_routines_results_modules(routines_with_params, module_name)
    |> Enum.map(fn {routine, routine_result_module_code} ->
      routine_result_struct_filename =
        routine
        |> Database.DbRoutine.to_routine_with_unique_name()
        |> Database.DbRoutine.get_routine_result_item_struct_name()
        |> IO.iodata_to_binary()
        |> Macro.underscore()

      filename = Path.join([output_location, "models", [routine_result_struct_filename, ".ex"]])

      if is_function(before_write_file) do
        before_write_file.(filename)
      end
      File.write!(
        filename,
        routine_result_module_code
      )
    end)
  end
end
