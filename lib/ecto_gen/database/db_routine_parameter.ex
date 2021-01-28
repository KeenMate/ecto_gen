defmodule EctoGen.Database.DbRoutineParameter do
  @fields [
    :position,
    :name,
    # type name
    :udt_name,
    :mode,
    :parameter_default
  ]

  @valid_udt_names [
    "text",
    "int",
    "int4",
    "int8",
    "int16",
    "bool",
    "date",
    "timestamp",
    "timestamptz"
  ]

  @enforce_keys @fields

  defstruct @fields

  require Logger

  alias EctoGen.Database.DbRoutineParameter, as: RoutineParameter

  @type t() :: %RoutineParameter{}

  def parse_from_db_row([position, name, mode, udt_name, parameter_default]) do
    with {:ok, udt_name_validated} <- check_udt_name(udt_name),
         {:ok, mode_validated} <- check_mode(mode) do
      {
        :ok,
        %RoutineParameter{
          position: position,
          name: name,
          mode: mode_validated,
          udt_name: udt_name_validated,
          parameter_default: parameter_default
        }
      }
    else
      err ->
        Logger.error("Could not parse routine param: #{inspect(err)}")
        err
    end
  end

  @doc """
  Returns binary containing spec representation of given udt name

  ## Examples
      iex> udt_name_to_elixir_term("text")
      "binary()"
      iex> udt_name_to_elixir_term("int")
      "integer()"
      iex> udt_name_to_elixir_term("timestamp")
      "DateTime.t()"
      iex> udt_name_to_elixir_term("timestamptz")
      "DateTime.t()"
  """
  def udt_name_to_elixir_term("text"), do: "binary()"
  def udt_name_to_elixir_term("int"), do: "integer()"
  def udt_name_to_elixir_term("int4"), do: "integer()"
  def udt_name_to_elixir_term("int8"), do: "integer()"
  def udt_name_to_elixir_term("int16"), do: "integer()"
  def udt_name_to_elixir_term("bool"), do: "boolean()"
  def udt_name_to_elixir_term("date"), do: "Date.t()"
  def udt_name_to_elixir_term("timestamp"), do: "DateTime.t()"
  def udt_name_to_elixir_term("timestamptz"), do: "DateTime.t()"

  defp check_udt_name(udt_name) when not is_binary(udt_name) do
    {:error, :einv_type}
  end

  defp check_udt_name(udt_name) when udt_name in @valid_udt_names, do: {:ok, udt_name}

  defp check_mode(mode) when not (mode in ["IN", "OUT"]) do
    {:error, :einv_mode}
  end

  defp check_mode(mode), do: {:ok, mode}
end
