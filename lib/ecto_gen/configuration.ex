defmodule EctoGen.Configuration do
  require Logger

  @allowed_schema_keys [:funcs, :ignored_funcs]

  def get_config() do
    db_otp_app = Application.get_env(:ecto_gen, :otp_app)
    db_config_key = Application.get_env(:ecto_gen, :db_config)

    # included_schemas: get_included_schemas_config()
    %{
      database: Application.get_env(db_otp_app, db_config_key),
      db_project: get_db_project(),
      output_location: Application.get_env(:ecto_gen, :output_location),
      output_module: Application.get_env(:ecto_gen, :output_module)
    }
  end

  def get_db_project() do
    value = Application.get_env(:ecto_gen, :db_project)

    value
    |> get_unknown_schema_keys()
    |> warn_about_unknown_schema_config_keys()

    value
    |> normalize_db_project_config()
  end

  defp normalize_db_project_config(config) do
    config
    |> Enum.map(fn
      {key, value} when is_atom(key) ->
        {Atom.to_string(key), value}

      {key, _value} = kv when is_binary(key) ->
        kv
    end)
  end

  defp warn_about_unknown_schema_config_keys(schemas_with_unknown_config_keys) do
    schemas_with_unknown_config_keys
    |> Enum.each(fn
      {_schema, []} ->
        nil

      {schema, unknown_keys} ->
        Logger.warn("Schema: #{schema} has some unknown keys: #{inspect(unknown_keys)}")
    end)
  end

  defp get_unknown_schema_keys(value) do
    value
    |> Enum.map(fn {schema, schema_config} ->
      {
        schema,
        schema_config
        |> Enum.filter(fn {k, _} -> not (k in @allowed_schema_keys) end)
        |> Enum.map(fn {key, _} -> key end)
      }
    end)
  end

  def get_included_schemas_config() do
    value = Application.get_env(:ecto_gen, :included_schemas)

    if not is_list(value) or Enum.any?(value, &(not is_binary(&1))) do
      raise "Invalid argument value for :included_schemas"
    end

    value
  end
end
