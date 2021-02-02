defmodule EctoGen.Database.DbRoutine do
  alias Mix.Shell.IO, as: MixIO

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
    MixIO.error(
      "Received invalid amount of columns when attempted to parse routine info row. value: #{
        inspect(value)
      }"
    )

    {:error, :einvcolumncount}
  end

  @doc """
  Returns fully-qualified module name where function's return struct should be.
  """
  @spec get_routine_result_item_module_name(t(), binary() | iodata()) :: iodata()
  def get_routine_result_item_module_name(
        %DbRoutine{name: routine_name, schema: routine_schema} = routine,
        module_name
      ) do
    case has_complex_return_type?(routine) do
      true ->
        result_item_name =
          get_routine_result_item_struct_name(routine_schema, routine_name)
          |> IO.iodata_to_binary()
          |> Macro.camelize()

        [module_name, ".Models.", result_item_name]

      false ->
        nil
    end
  end

  @spec get_routine_result_item_struct_name(binary() | iodata(), binary() | iodata()) :: iodata()
  def get_routine_result_item_struct_name("public", routine_name) do
    [routine_name, "Item"]
  end

  def get_routine_result_item_struct_name(routine_schema, routine_name) do
    [routine_schema, "_", routine_name, "Item"]
  end

  @spec get_routine_parser_name(binary() | iodata(), binary() | iodata()) :: iodata()
  def get_routine_parser_name("public", routine_name), do: [routine_name, "Parser"]

  def get_routine_parser_name(routine_schema, routine_name) do
    [routine_schema, "_", routine_name, "Parser"]
  end

  def has_complex_return_type?(%DbRoutine{data_type: data_type}) do
    data_type in ["USER-DEFINED", "record"]
  end
end
