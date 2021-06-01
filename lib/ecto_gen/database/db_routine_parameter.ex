defmodule EctoGen.Database.DbRoutineParameter do
  alias Mix.Shell.IO, as: MixIO

  @fields [
    :position,
    :name,
    # type name
    :udt_name,
    :mode,
    :parameter_default
  ]

  @enforce_keys @fields

  defstruct @fields

  alias EctoGen.Database.DbRoutineParameter, as: RoutineParameter

  @type t() :: %RoutineParameter{}

  def parse_from_db_row([position, name, mode, udt_name, parameter_default]) do
    with {:ok, mode_validated} <- check_mode(mode) do
      {
        :ok,
        %RoutineParameter{
          position: position,
          name: name,
          mode: mode_validated,
          udt_name: udt_name,
          parameter_default: parameter_default
        }
      }
    else
      err ->
        MixIO.error("Could not parse routine param: #{inspect(err)}")
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
  def udt_name_to_elixir_term(text) when text in ["text", "varchar", "uuid"], do: "binary()"
  def udt_name_to_elixir_term("int" <> _), do: "integer()"
  def udt_name_to_elixir_term("bool"), do: "boolean()"
  def udt_name_to_elixir_term("date"), do: "Date.t()"
  def udt_name_to_elixir_term("timestamp"), do: "DateTime.t()"
  def udt_name_to_elixir_term("timestamptz"), do: "DateTime.t()"
  def udt_name_to_elixir_term(_), do: "any()"

  defp check_mode(mode) when not (mode in ["IN", "OUT"]) do
    {:error, :einv_mode}
  end

  defp check_mode(mode), do: {:ok, mode}
end
