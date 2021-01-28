defmodule EctoGen.Database.DbRoutine do
  @fields [
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

  alias EctoGen.Database.DbRoutine

  @type t() :: %DbRoutine{}

  def parse_from_db_row([schema, routine_name, specific_name, data_type, type_schema, type_name]) do
    {
      :ok,
      %DbRoutine{
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
    Logger.error("Received invalid amount of columns when attempted to parse routine info row", value: inspect(value))
    {:error, :einvcolumncount}
  end

  @doc """
  Returns fully-qualified module name where function's return struct should be.
  """
  @spec get_routine_result_item_module_name(t(), binary() | iodata()) :: iodata()
  def get_routine_result_item_module_name(%DbRoutine{name: routine_name, schema: routine_schema}, module_name) do
    result_item_name =
      [routine_schema, "_", routine_name, "ResultItem"]
      |> IO.iodata_to_binary()
      |> Macro.camelize()

    [module_name, ".Modules.", result_item_name]
  end

  def has_complex_return_type?(%DbRoutine{data_type: data_type}) do
    data_type in ["USER-DEFINED", "record"]
  end
end
