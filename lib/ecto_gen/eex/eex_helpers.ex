defmodule EctoGen.EEx.Helpers do
  @moduledoc """
  This module contains functions for convenient writing of generated elixir modules
  """

  alias EctoGen.Database.{DbRoutine, DbRoutineParameter}

  require DbRoutine

  @spec generate_params_list([DbRoutineParameter.t()], boolean()) :: iodata()
  def generate_params_list(routine_params, with_default \\ false) do
    routine_params
    |> sort_function_params_by_postion()
    |> Enum.reduce(
      [],
      fn %{name: param_name, parameter_default: default_value}, acc ->
        [
          if acc == [] do
            acc
          else
            [acc, ", "]
          end,
          param_name,
          if with_default and default_value do
            [" \\\\ ", value_not_provided_token()]
          else
            []
          end
        ]
      end
    )
  end

  @spec generate_sql_query_params_assignments([DbRoutineParameter.t()]) :: iodata()
  def generate_sql_query_params_assignments(routine_params) do
    params_list =
      Enum.reduce(
        routine_params,
        [],
        fn %{name: param_name}, acc ->
          [
            if acc == [] do
              acc
            else
              [acc, ", "]
            end,
            param_name
          ]
        end)

    [
      "[",
      params_list,
      "]",
      "|> Enum.filter(fn x -> x != ",
      value_not_provided_token(),
      " end)"
    ]
  end

  @spec generate_sql_params(list()) :: iodata()
  def generate_sql_params(routine_params) do
    routine_params
    |> Enum.with_index()
    |> Enum.reduce(
      [],
      fn {%DbRoutineParameter{original_name: original_name, name: name}, idx}, acc ->
        [
          acc,
          "\#{if ",
          name,
          " == ",
          value_not_provided_token(),
          ", do: \"\", else: \", ",
          original_name,
          " := $",
          Integer.to_string(idx + 1),
          "\"}"
        ]
    end)
  end

  @spec generate_function_spec(
          DbRoutine.t(),
          list(DbRoutineParameter.t()),
          binary() | iodata()
        ) :: iodata()
  def generate_function_spec(routine, input_params, module_name) do
    result = ["@spec ", DbRoutine.get_routine_function_name(routine), "("]

    result =
      input_params
      |> sort_function_params_by_postion()
      |> Enum.with_index()
      |> Enum.reduce(result, fn
        {
          %{udt_name: udt_name, parameter_default: has_default},
          index
        },
        acc ->
          [
            acc,
            if(index != 0, do: ", ", else: []),
            DbRoutineParameter.udt_name_to_elixir_term(udt_name),
            if(has_default, do: [" | ", value_not_provided_token()], else: [])
          ]
      end)

    [result, ") :: ", get_function_return_spec(routine, module_name)]
  end

  def sort_function_params_by_postion(routine_params) do
    routine_params
    |> Enum.sort_by(& &1.position, :asc)
  end

  @spec get_function_return_type_spec(DbRoutine.t(), binary() | iodata()) :: iodata()
  def get_function_return_type_spec(routine, module_name) do
    [
      "[",
      case {
        DbRoutine.has_complex_return_type?(routine),
        DbRoutine.get_routine_result_item_module_name(routine, module_name)
      } do
        {true, routine_result_item_module_name} when routine_result_item_module_name != nil ->
          [DbRoutine.get_routine_result_item_module_name(routine, module_name), ".t()"]

        _ ->
          DbRoutineParameter.udt_name_to_elixir_term(routine.type_name)
      end,
      "]"
    ]
  end

  @spec get_routine_parser_module_name(binary() | iodata(), binary() | iodata()) :: iodata()
  def get_routine_parser_module_name(module_name, function_name) do
    parser_module_name =
      [function_name, "_parser"]
      |> IO.iodata_to_binary()
      |> Macro.camelize()

    [module_name, ".Parsers.", parser_module_name]
  end

  @spec get_routine_parse_function_name(binary() | iodata()) :: iodata()
  def get_routine_parse_function_name(function_name, per_row \\ false) do
    [
      "parse_",
      function_name,
      "_result",
      if per_row do
        "_row"
      else
        []
      end
    ]
  end

  @doc """
  Removes underscores from param names
  """
  def trim_routine_params_names(routine_params) do
    routine_params
    |> Enum.map(&%DbRoutineParameter{&1 | name: &1.name |> String.trim("_")})
  end

  def simple_return_type_param_name(), do: "value"

  def error_tuple_spec() do
    "{:error, any()}"
  end

  @spec value_not_provided_token() :: binary()
  def value_not_provided_token() do
    ":eg_value_not_provided"
  end

  defp get_function_return_spec(routine, module_name) do
    if DbRoutine.has_return_type(routine) do
      [error_tuple_spec(), " | {:ok, ", get_function_return_type_spec(routine, module_name), "}"]
    else
      [error_tuple_spec(), " | :ok"]
    end
  end
end
