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
      (if is_function_header, do: ["pid"], else: []),
      fn %{name: param_name, parameter_default: default_value}, acc ->
        [
          if acc == [] do
            acc
          else
            [acc, ", "]
          end,
          param_name,
          if is_function_header and default_value  do
            # todo: Think of a better way
            # note: This does remove possibility for user to specify nil intentionally
            # in case it will be removed from sql query during actual function call
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
        if (&2 == []) do
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
    result = ["@spec ", get_routine_function_name(routine), "(pid()"]

    result =
      input_params
      |> sort_function_params_by_postion()
      |> Enum.reduce(result, fn %{udt_name: udt_name}, acc ->
        [
          acc,
          ", ",
          DbRoutineParameter.udt_name_to_elixir_term(udt_name)
        ]
      end)

    [result, ") :: ", get_function_return_spec(routine, module_name)]
  end

  def sort_function_params_by_postion(routine_params) do
    routine_params
    |> Enum.sort_by(& &1.position, :asc)
  end

  @spec get_function_return_spec(DbRoutine.t(), binary() | iodata()) :: iodata()
  def get_function_return_spec(routine, module_name) do
    if DbRoutine.has_complex_return_type?(routine) do
      [DbRoutine.get_routine_result_item_module_name(routine, module_name), ".t()"]
    else
      simple_return_type_param_name()
    end
  end

  def get_routine_function_name(%DbRoutine{schema: schema, name: name}) do
    [schema, "_", name]
  end

  @spec get_routine_parse_function_name(binary() | iodata()) :: iodata()
  def get_routine_parse_function_name(function_name, per_row \\ false) do
    ["parse_", function_name, "_result", if per_row do "_row" else [] end]
  end

  @doc """
  Removes underscores from param names
  """
  def trim_routine_params_names(routine_params) do
    routine_params
    |> Enum.map(&(%DbRoutineParameter{&1 | name: &1.name |> String.trim("_")}))
  end

  def simple_return_type_param_name(), do: "value"
end
