defmodule EctoGen.EEx.Helpers do
  @moduledoc """
  This module contains functions for convenient writing of generated elixir modules
  """

  alias EctoGen.Database.{DbRoutine, DbRoutineParameter}

  require DbRoutine

  @spec generate_function_params([DbRoutineParameter.t()], boolean()) :: iodata()
  def generate_function_params(routine_params, is_function_header \\ false) do
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
          if is_function_header and default_value do
            " \\\\ nil"
          else
            []
          end
        ]
      end
    )
  end

  @spec generate_sql_params(list()) :: iodata()
  def generate_sql_params(l) do
    l
    |> Enum.with_index()
    |> Enum.reduce(
      [],
      &[
        if &2 == [] do
          []
        else
          [&2, ", "]
        end,
        "$",
        Integer.to_string(elem(&1, 1) + 1)
      ]
    )
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
            if(has_default, do: " | nil", else: [])
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

  defp get_function_return_spec(routine, module_name) do
    if DbRoutine.has_return_type(routine) do
      [error_tuple_spec(), " | {:ok, ", get_function_return_type_spec(routine, module_name), "}"]
    else
      [error_tuple_spec(), " | :ok"]
    end
  end
end
