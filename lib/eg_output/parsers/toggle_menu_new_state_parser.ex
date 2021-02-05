# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule MyApp.Database.Parsers.ToggleMenuNewStateParser do
  @moduledoc """
  This module contains functions to parse output from db's stored procedure's calls
  """

  require Logger

  @spec parse_toggle_menu_new_state_result({:ok, Postgrex.Result.t()} | {:error, any()}) ::
          {:ok,
           [
             MyApp.Database.Models.ToggleMenuNewStateItem.t()
           ]}
          | {:error, any()}
  def parse_toggle_menu_new_state_result({:error, reason} = err) do
    Logger.error("Error occured while calling stored procedure",
      procedure: "toggle_menu_new_state",
      reason: inspect(reason)
    )

    err
  end

  def parse_toggle_menu_new_state_result({:ok, %Postgrex.Result{rows: rows}}) do
    Logger.debug("Parsing successful response from database")

    parsed_results =
      rows
      |> Enum.map(&parse_toggle_menu_new_state_result_row/1)

    # todo: Handle rows that could not be parsed

    successful_results =
      parsed_results
      |> Enum.filter(&(elem(&1, 0) == :ok))
      |> Enum.map(&elem(&1, 1))

    Logger.debug("Parsed response")

    {:ok, successful_results}
  end

  def parse_toggle_menu_new_state_result_row([
        menu_id,
        code,
        title_cs,
        title_en,
        node_path,
        parent_node_path,
        has_children,
        default_item_type_code,
        priority,
        menu_item_id,
        price,
        menu_description_cs,
        menu_description_en,
        menu_is_new,
        menu_item_is_new,
        menu_is_visible,
        menu_item_is_visible,
        is_numbered,
        numbering_per_category,
        ignore_numbering,
        item_title_cs,
        item_title_en,
        desc_cs,
        desc_en,
        allergens,
        vegetarian,
        spiciness
      ]) do
    {
      :ok,
      %MyApp.Database.Models.ToggleMenuNewStateItem{
        menu_id: menu_id,
        code: code,
        title_cs: title_cs,
        title_en: title_en,
        node_path: node_path,
        parent_node_path: parent_node_path,
        has_children: has_children,
        default_item_type_code: default_item_type_code,
        priority: priority,
        menu_item_id: menu_item_id,
        price: price,
        menu_description_cs: menu_description_cs,
        menu_description_en: menu_description_en,
        menu_is_new: menu_is_new,
        menu_item_is_new: menu_item_is_new,
        menu_is_visible: menu_is_visible,
        menu_item_is_visible: menu_item_is_visible,
        is_numbered: is_numbered,
        numbering_per_category: numbering_per_category,
        ignore_numbering: ignore_numbering,
        item_title_cs: item_title_cs,
        item_title_en: item_title_en,
        desc_cs: desc_cs,
        desc_en: desc_en,
        allergens: allergens,
        vegetarian: vegetarian,
        spiciness: spiciness
      }
    }
  end

  def parse_toggle_menu_new_state_result_row(_unknown_row) do
    Logger.warn("Found result row that does not have valid number of columns")

    {:error, :einv_columns}
  end
end