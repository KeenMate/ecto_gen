defmodule EctoGen.Database do
  use GenServer

  require Logger

  alias EctoGen.Database.{DbRoutine, DbRoutineParameter}

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(arg) do
    {:ok, db_pid} = Postgrex.start_link(arg)

    {:ok, db_pid}
  end

  @spec get_routines(binary()) :: {:ok, [DbRoutine.t()]} | {:error, Postgrex.Error.t()}
  def get_routines(schema) do
    GenServer.call(__MODULE__, {:get_routines, schema})
  end

  @spec get_routine_params(binary(), binary(), binary() | nil, binary() | nil) ::
          {:ok, [DbRoutineParameter.t()]} | {:error, Postgrex.Error.t()}
  def get_routine_params(
        schema,
        routine_specific_name,
        routine_return_type_schema \\ nil,
        routine_return_type \\ nil
      ) do
    GenServer.call(
      __MODULE__,
      {:get_routine_params, schema, routine_specific_name, routine_return_type_schema,
       routine_return_type}
    )
  end

  # GenServer implementation

  def handle_call(
        {:get_routine_params, schema, routine_specific_name, routine_return_type_schema,
         routine_return_type},
        _from,
        state
      ) do
    Logger.debug("Fetching routine params", routine: inspect(routine_specific_name))

    with is_with_return_type <- routine_return_type != nil and routine_return_type_schema != nil,
         query_text <- get_query_text_for_get_routine_params(is_with_return_type),
         query_params <-
           get_query_params_for_get_routine_params(
             is_with_return_type,
             schema,
             routine_specific_name,
             routine_return_type,
             routine_return_type_schema
           ),
         result <-
           state
           |> Postgrex.query(
             query_text,
             query_params
           )
           |> process_get_routine_params_result(schema, routine_specific_name) do
      {:reply, result, state}
    end
  end

  def handle_call({:get_routines, schema}, _from, state) when is_binary(schema) do
    Logger.debug("Fetching all routines for given schema from db", schema: inspect(schema))

    result =
      state
      |> Postgrex.query(
        """
          select routine_schema::text,
            routine_name::text,
            specific_name::text,
            data_type,
            type_udt_schema::text,
            type_udt_name::text
          from information_schema.routines
          where specific_schema = $1;
        """,
        [schema]
      )
      |> process_get_routines_result(schema)

    {:reply, result, state}
  end

  # Private members

  defp get_query_params_for_get_routine_params(
         is_with_return_type,
         schema,
         routine_specific_name,
         routine_return_type,
         routine_return_type_schema
       ) do
    query_params = [schema, routine_specific_name]

    if is_with_return_type do
      query_params ++ [routine_return_type, routine_return_type_schema]
    else
      query_params
    end
  end

  defp get_query_text_for_get_routine_params(is_with_return_type) do
    query_text = """
      select ordinal_position::int,
           parameter_name::text,
           parameter_mode::text,
           udt_name::text,
           parameter_default is not null as is_nullable
      from information_schema.parameters
      where specific_schema = $1
        and specific_name = $2
    """

    if is_with_return_type do
      query_text <>
        """
        union
          select c.ordinal_position::int, c.column_name::text, 'OUT', c.udt_name::text, c.column_default is not null
          from information_schema.columns c
          where c.table_name = $3
            and c.table_schema = coalesce($4, 'public')
          order by ordinal_position;
        """
    else
      query_text
    end
  end

  defp process_get_routine_params_result({:error, reason} = err, schema, routine_specific_name) do
    Logger.error("Error occured while retrieving database routine params",
      reason: inspect(reason),
      schema: inspect(schema),
      routine_specific_name: inspect(routine_specific_name)
    )

    err
  end

  defp process_get_routine_params_result(
         {:ok, %Postgrex.Result{columns: _columns, rows: rows}},
         _schema,
         _routine_specific_name
       ) do
    result =
      rows
      |> Enum.map(&DbRoutineParameter.parse_from_db_row/1)

    successful_results =
      result
      |> Enum.filter(&(elem(&1, 0) == :ok))
      |> Enum.map(fn {:ok, routine_param} -> routine_param end)

    {:ok, successful_results}
  end

  defp process_get_routines_result({:error, reason} = err, schema) do
    Logger.error("Error occured while retrieving database routines",
      reason: inspect(reason),
      schema: inspect(schema)
    )

    err
  end

  defp process_get_routines_result(
         {:ok, %Postgrex.Result{columns: _columns, rows: rows}},
         _schema
       ) do
    result =
      rows
      |> Enum.map(&DbRoutine.parse_from_db_row/1)

    successful_results =
      result
      |> Enum.filter(&(elem(&1, 0) == :ok))
      |> Enum.map(fn {:ok, routine} -> routine end)

    {:ok, successful_results}
  end
end
