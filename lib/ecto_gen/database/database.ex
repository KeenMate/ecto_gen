defmodule EctoGen.Database do
  alias EctoGen.Database.{DbRoutine, DbRoutineParameter}
  alias Mix.Shell.IO, as: MixIO

  @spec get_routines(pid(), binary()) :: {:ok, [DbRoutine.t()]} | {:error, Postgrex.Error.t()}
  def get_routines(pg_pid, schema) do
    Postgrex.query(
      pg_pid,
      """
      select row_number() over (PARTITION BY routine_schema, routine_name),
        r.routine_schema::text,
        r.routine_name::text,
        r.specific_name::text,
        r.data_type,
        r.type_udt_schema::text,
        r.type_udt_name::text
      from information_schema.routines r
      left join (select specific_schema, specific_name, count(*) as param_count from
        information_schema.parameters p
        group by  specific_schema, specific_name) p on p.specific_schema = r.specific_schema and p.specific_name = r.specific_name
      where r.specific_schema = $1
      order by routine_schema, routine_name;
      """,
      [schema]
    )
    |> process_get_routines_result(schema)
  end

  @spec get_routine_params(pid(), binary(), binary(), binary() | nil, binary() | nil) ::
          {:ok, [DbRoutineParameter.t()]} | {:error, Postgrex.Error.t()}
  def get_routine_params(
        pg_pid,
        schema,
        routine_specific_name,
        routine_return_type_schema \\ nil,
        routine_return_type \\ nil
      ) do
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
           Postgrex.query(
             pg_pid,
             query_text,
             query_params
           )
           |> process_get_routine_params_result(schema, routine_specific_name) do
      result
    end
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
        union
          select a.ordinal_position::int, a.attribute_name::text, 'OUT', a.attribute_udt_name::text, is_nullable = 'YES'
          from information_schema.attributes a
          where a.udt_name = $3
            and a.udt_schema = coalesce($4, 'public')
          order by ordinal_position;
        """
    else
      query_text
    end
  end

  defp process_get_routine_params_result({:error, reason} = err, schema, routine_specific_name) do
    Mix.raise("""
    Error occured while retrieving database routine params.
    schema: #{inspect(schema)} routine: #{inspect(routine_specific_name)}
    reason: #{inspect(reason)}
    """)

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
    MixIO.error(
      "Error occured while retrieving database routines. schema: #{inspect(schema)}." <>
        "reason: #{inspect(reason)}"
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
