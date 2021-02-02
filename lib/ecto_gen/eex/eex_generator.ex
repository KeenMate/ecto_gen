defmodule EctoGen.EEx.EExGenerator do
  require EEx
  require Logger

  import EctoGen.EEx.Helpers

  alias EctoGen.Database
  alias Database.Helpers, as: DbHelpers

  @type routine_with_params :: {Database.DbRoutine.t(), [Database.DbRoutineParameter.t()]}

  @file_templates_overrides Application.get_env(:ecto_gen, :template_overrides, [])

  @eex_templates_path Path.join(:code.priv_dir(:ecto_gen), "eex_templates")

  EEx.function_from_file(
    :defp,
    :routine_result_item_eex,
    Keyword.get(@file_templates_overrides, :routine_result) ||
      Path.join(@eex_templates_path, "routine_result_item.ex.eex"),
    [:assigns]
  )

  EEx.function_from_file(
    :defp,
    :routine_eex,
    Keyword.get(@file_templates_overrides, :routine) ||
      Path.join(@eex_templates_path, "routine.ex.eex"),
    [
      :assigns
    ]
  )

  EEx.function_from_file(
    :defp,
    :routine_parser_eex,
    Keyword.get(@file_templates_overrides, :routine_parser) ||
      Path.join(@eex_templates_path, "routine_parser.ex.eex"),
    [
      :assigns
    ]
  )

  EEx.function_from_file(
    :defp,
    :db_context_module_eex,
    Keyword.get(@file_templates_overrides, :db_module) ||
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
            |> Enum.filter(&(&1.mode == "OUT"))
            |> trim_routine_params_names()
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

  @spec generate_routines_parser_modules(
          [routine_with_params()],
          binary() | iodata(),
          binary() | iodata()
        ) :: [
          {Database.DbRoutine.t(), iodata()}
        ]
  def generate_routines_parser_modules(routines_with_params, module_name, include_sensitive_data) do
    routines_with_params
    |> Enum.map(fn {routine, routine_params} ->
      {
        routine,
        prepare_routine_parser_assings(
          routine,
          routine_params,
          module_name,
          include_sensitive_data
        )
      }
    end)
    |> Enum.map(fn {routine, assigns} ->
      result =
        assigns
        |> routine_parser_eex()

      {
        routine,
        result
        |> Code.format_string!()
      }
    end)
  end

  @spec prepare_context_module_assigns([routine_with_params()], keyword()) :: keyword()
  def prepare_context_module_assigns(routines_with_params, opts) do
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

  @spec prepare_routine_assigns(
          Database.DbRoutine.t(),
          [Database.DbRoutineParameter.t()],
          binary()
        ) :: keyword()
  def prepare_routine_assigns(routine, routine_params, module_name) do
    input_routine_params =
      DbHelpers.filter_routine_params(routine_params, :input)
      |> trim_routine_params_names()

    function_name = get_routine_function_name(routine)

    [
      routine: routine,
      function_name: function_name,
      function_spec: generate_function_spec(routine, input_routine_params, module_name),
      sql_params: generate_sql_params(input_routine_params),
      input_params: generate_function_params(input_routine_params),
      input_params_with_default: generate_function_params(input_routine_params, true),
      parse_function_name: [
        get_routine_parser_module_name(module_name, function_name),
        ".",
        get_routine_parse_function_name(function_name)
      ]
    ]
  end

  def prepare_routine_parser_assings(routine, routine_params, module_name, include_sensitive_data) do
    output_routine_params =
      DbHelpers.filter_routine_params(routine_params, :output)
      |> trim_routine_params_names()

    routine_has_complex_data = Database.DbRoutine.has_complex_return_type?(routine)

    function_name = get_routine_function_name(routine)

    [
      module_name: get_routine_parser_module_name(module_name, function_name),
      function_name: function_name,
      parse_function_name_result_row: get_routine_parse_function_name(function_name, true),
      routine_has_complex_data: routine_has_complex_data,
      output_routine_params: output_routine_params,
      parse_function_name: get_routine_parse_function_name(function_name),
      output_params:
        if routine_has_complex_data do
          generate_function_params(output_routine_params)
        else
          simple_return_type_param_name()
        end,
      routine_result_item_module_name:
        Database.DbRoutine.get_routine_result_item_module_name(routine, module_name),
      include_sensitive_data: include_sensitive_data
    ]
  end
end
