defmodule EctoGen.Database.Helpers do
  alias EctoGen.Database

  @spec get_routines_with_params_to_create(pid(), Keyword.t()) :: [
          {Database.DbRoutine.t(), [Database.DbRoutineParameter.t()]}
        ]
  def get_routines_with_params_to_create(pg_pid, db_project) do
    pg_pid
    |> get_routines_to_create(db_project)
    |> Enum.map(&Task.async(fn -> get_routine_params(pg_pid, &1) end))
    |> Enum.map(&Task.await/1)
    # todo: do something with routine params calls that did not succeed
    |> Enum.filter(&(elem(&1, 0) == :ok))
    |> Enum.map(&elem(&1, 1))
  end

  def get_routines_to_create(pg_pid, db_project) do
    db_project
    |> Enum.flat_map(fn {schema, config} ->
      pg_pid
      |> Database.get_routines(schema)
      |> process_loaded_routines(config)
    end)
  end

  def get_routine_params(pg_pid, %Database.DbRoutine{data_type: "USER-DEFINED"} = routine) do
    case Database.get_routine_params(
           pg_pid,
           routine.schema,
           routine.specific_name,
           routine.type_schema,
           routine.type_name
         ) do
      {:ok, routine_params} ->
        {:ok, {routine, routine_params}}

      {:error, _reason} = err ->
        err
    end
  end

  def get_routine_params(pg_pid, %Database.DbRoutine{} = routine) do
    case Database.get_routine_params(pg_pid, routine.schema, routine.specific_name) do
      {:ok, routine_params} ->
        {:ok, {routine, routine_params}}

      {:error, _reason} = err ->
        err
    end
  end

  @spec filter_routine_params([Database.DbRoutineParameter.t()], :input | :output) :: [
          Database.DbRoutineParameter.t()
        ]
  def filter_routine_params(routine_params, :input) do
    routine_params
    |> filter_routine_params_by_mode("IN")
  end

  def filter_routine_params(routine_params, :output) do
    routine_params
    |> filter_routine_params_by_mode("OUT")
  end

  # Private members

  defp filter_routine_params_by_mode(routine_params, mode) do
    routine_params
    |> Enum.filter(&(&1.mode == mode))
  end

  defp process_loaded_routines({:error, _reason} = err, _schema_config) do
    err
  end

  defp process_loaded_routines({:ok, routines}, schema_config) do
    funcs = Keyword.get(schema_config, :funcs)
    ignored_funcs = Keyword.get(schema_config, :ignored_funcs, [])

    case {funcs, ignored_funcs} do
      {f, ignored} when f in ["*", nil] and is_list(ignored) ->
        filter_ignored_routines(routines, ignored)

      {f, ignored} when is_list(f) and (is_list(ignored) or ignored == nil) ->
        filter_included_routines(routines, f, ignored)
    end
  end

  defp filter_included_routines(routines, included_funcs, ignored) do
    routines
    |> Enum.filter(fn routine ->
      Enum.any?(included_funcs, &(routine.name == &1))
    end)
    |> filter_ignored_routines(ignored)
  end

  defp filter_ignored_routines(routines, nil), do: routines

  defp filter_ignored_routines(routines, ignored_funcs) do
    routines
    |> Enum.filter(fn routine ->
      not Enum.any?(ignored_funcs, &(routine.name == &1))
    end)
  end
end
