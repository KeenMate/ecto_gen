# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule MyApp.Database.DbContext do
  @moduledoc """
  This module contains functions for calling DB's stored procedures.
  Functions of this module uses `query/2` function of Repo that you have provided (`db_config` key of configuration)
  """

  require Logger

  import Elixir.MyApp.Repo, only: [query: 2]

  @spec get_all_menu(binary() | nil) ::
          {:error, any()} | {:ok, [MyApp.Database.Models.GetAllMenuItem.t()]}
  def get_all_menu(code \\ nil) do
    Logger.debug("Calling stored procedure", procedure: "get_all_menu")

    query(
      "select * from public.get_all_menu($1)",
      [code]
    )
    |> MyApp.Database.Parsers.GetAllMenuParser.parse_get_all_menu_result()
  end

  @spec this_is_procedure(binary()) :: {:error, any()} | :ok
  def this_is_procedure(asd) do
    Logger.debug("Calling stored procedure", procedure: "this_is_procedure")

    query(
      "select * from public.this_is_procedure($1)",
      [asd]
    )

    :ok
  end

  @spec toggle_menu_new_state(binary()) ::
          {:error, any()} | {:ok, [MyApp.Database.Models.ToggleMenuNewStateItem.t()]}
  def toggle_menu_new_state(menu_path) do
    Logger.debug("Calling stored procedure", procedure: "toggle_menu_new_state")

    query(
      "select * from public.toggle_menu_new_state($1)",
      [menu_path]
    )
    |> MyApp.Database.Parsers.ToggleMenuNewStateParser.parse_toggle_menu_new_state_result()
  end

  @spec toggle_menu_visibility(binary()) ::
          {:error, any()} | {:ok, [MyApp.Database.Models.ToggleMenuVisibilityItem.t()]}
  def toggle_menu_visibility(menu_path) do
    Logger.debug("Calling stored procedure", procedure: "toggle_menu_visibility")

    query(
      "select * from public.toggle_menu_visibility($1)",
      [menu_path]
    )
    |> MyApp.Database.Parsers.ToggleMenuVisibilityParser.parse_toggle_menu_visibility_result()
  end
end