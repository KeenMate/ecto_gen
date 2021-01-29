defmodule EctoGen.EEx.EExGenerator do
  require EEx
  require Logger

  import EctoGen.EEx.Helpers

  alias EctoGen.Database
  alias Database.Helpers, as: DbHelpers

  @type routine_with_params :: {Database.DbRoutine.t(), [Database.DbRoutineParameter.t()]}

  @eex_templates_path Path.join(:code.priv_dir(:ecto_gen), "eex_templates")

  EEx.function_from_file(
    :defp,
    :routine_result_item_eex,
    Path.join(@eex_templates_path, "routine_result_item.ex.eex"),
    [:assigns]
  )

  EEx.function_from_file(:defp, :routine_eex, Path.join(@eex_templates_path, "routine.ex.eex"), [
    :assigns
  ])

  EEx.function_from_file(
    :defp,
    :db_context_module_eex,
    Path.join(@eex_templates_path, "db_module.ex.eex"),
    [:assigns]
  )

  @spec generate_context_module([routine_with_params()], keyword()) ::
          iodata()
  def generate_context_module(routines_with_params, opts \\ []) do
    result =
      routines_with_params
      |> prepare_context_module_assigns(opts)
      |> db_context_module_eex()

    IO.puts("Current dir: #{File.cwd!()}")
    File.write("temp.ex", result)

    result
    |> Code.format_string!()
  end

  @spec generate_routines_results_modules(
          [routine_with_params()],
          binary() | iodata()
        ) :: [{Database.DbRoutine.t(), iodata()}]
  def generate_routines_results_modules(routines_with_params, module_name) do
    routines_with_params
    |> Enum.filter(&(elem(&1, 0).data_type in ["USER-DEFINED", "record"]))
    |> Enum.map(fn {routine, routine_params} ->
      {
        routine,
        [
          module_name:
            Database.DbRoutine.get_routine_result_item_module_name(routine, module_name),
          routine_result_fields:
            routine_params
            |> Enum.map(& &1.name)
        ]
      }
    end)
    |> Enum.map(fn {routine, assigns} ->
      result =
        assigns
        |> routine_result_item_eex()

      {
        routine,
        result
        |> Code.format_string!()
      }
    end)
  end

  @spec prepare_context_module_assigns([routine_with_params()], keyword()) :: keyword()
  def prepare_context_module_assigns(routines_with_params, opts) do
    Logger.debug("Preparing schema assigns")

    module_name = opts |> Keyword.get(:module_name)

    routines_assigns =
      routines_with_params
      |> Enum.map(fn {routine, routine_params} ->
        prepare_routine_assigns(routine, routine_params, module_name)
      end)

    [
      routines: routines_assigns,
      module_name: module_name
    ]
  end

  def prepare_routine_assigns(routine, routine_params, module_name) do
    input_routine_params =
      DbHelpers.filter_routine_params(routine_params, :input)
      |> trim_routine_params_names()

    output_routine_params =
      DbHelpers.filter_routine_params(routine_params, :output)
      |> trim_routine_params_names()

    function_name = get_routine_function_name(routine)

    routine_has_complex_data = Database.DbRoutine.has_complex_return_type?(routine)

    [
      routine: routine,
      function_name: function_name,
      function_spec: generate_function_spec(routine, input_routine_params, module_name),
      sql_params: generate_sql_params(input_routine_params),
      input_params: generate_function_params(input_routine_params),
      input_params_with_default: generate_function_params(input_routine_params, true),
      output_params:
        if routine_has_complex_data do
          generate_function_params(output_routine_params)
        else
          simple_return_type_param_name()
        end,
      output_routine_params: output_routine_params,
      routine_has_complex_data: routine_has_complex_data,
      parse_function_name: get_routine_parse_function_name(function_name),
      parse_function_name_result_row: get_routine_parse_function_name(function_name, true),
      routine_result_item_module_name:
        Database.DbRoutine.get_routine_result_item_module_name(routine, module_name)
    ]
  end
end
