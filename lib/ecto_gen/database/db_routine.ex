defmodule EctoGen.Database.DbRoutine do
  @fields [
    :row_number,
    :schema,
    :name,
    :specific_name,
    :data_type,
    :type_schema,
    :type_name
  ]

  @enforce_keys @fields

  defstruct @fields

  require Logger

  alias Mix.Shell.IO, as: MixIO
  alias EctoGen.Database.DbRoutine

  @type t() :: %DbRoutine{}

  def parse_from_db_row([
        row_number,
        schema,
        routine_name,
        specific_name,
        data_type,
        type_schema,
        type_name
      ]) do
    {
      :ok,
      %DbRoutine{
        row_number: row_number,
        schema: schema,
        name: routine_name,
        specific_name: specific_name,
        data_type: data_type,
        type_schema: type_schema,
        type_name: type_name
      }
    }
  end

  def parse_from_db_row(value) do
    MixIO.error(
      "Received invalid amount of columns when attempted to parse routine info row. value: #{
        inspect(value)
      }"
    )

    {:error, :einvcolumncount}
  end

  @doc """
  Returns the name used for function in new generated code.
  Makes sure each function overload distinguisheable.
  """
  @spec get_routine_function_name(t()) :: binary() | iodata()
  def get_routine_function_name(%DbRoutine{schema: "public", name: name}) do
    name
  end

  def get_routine_function_name(%DbRoutine{schema: schema, name: name}) do
    [schema, "_", name]
  end

  def to_routine_with_unique_name(%DbRoutine{row_number: row_number, name: name} = routine)
      when is_number(row_number) and row_number > 1 do
    %DbRoutine{
      routine
      | row_number: {:used, row_number},
        name: [name, "_", Integer.to_string(row_number - 1)]
    }
  end

  def to_routine_with_unique_name(routine), do: routine

  @doc """
  Returns fully-qualified module name where function's return struct should be.
  """
  @spec get_routine_result_item_module_name(t(), binary() | iodata()) :: iodata() | nil
  def get_routine_result_item_module_name(
        %DbRoutine{} = routine,
        module_name
      ) do
    case has_complex_return_type?(routine) do
      true ->
        result_item_name =
          routine
          |> get_routine_result_item_struct_name()
          |> IO.iodata_to_binary()
          |> Macro.camelize()

        [module_name, ".Models.", result_item_name]

      false ->
        nil
    end
  end

  @spec get_routine_result_item_struct_name(t()) :: iodata()
  def get_routine_result_item_struct_name(%DbRoutine{schema: "public", name: routine_name}) do
    [routine_name, "Item"]
  end

  def get_routine_result_item_struct_name(%DbRoutine{schema: routine_schema, name: routine_name}) do
    [routine_schema, "_", routine_name, "Item"]
  end

  @spec get_routine_parser_name(t()) :: iodata()
  def get_routine_parser_name(%DbRoutine{schema: "public", name: routine_name}),
    do: [routine_name, "Parser"]

  def get_routine_parser_name(%DbRoutine{schema: routine_schema, name: routine_name}) do
    [routine_schema, "_", routine_name, "Parser"]
  end

  def has_complex_return_type?(%DbRoutine{data_type: data_type}) do
    data_type in ["USER-DEFINED", "record"]
  end

  def has_return_type(%DbRoutine{} = routine) do
    routine.data_type != nil or
      routine.type_name != nil or
      routine.type_schema != nil
  end
end
