# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule MyApp.Database.Models.ToggleMenuVisibilityItem do
  @fields [
    :menu_id,
    :code,
    :title_cs,
    :title_en,
    :node_path,
    :parent_node_path,
    :has_children,
    :default_item_type_code,
    :priority,
    :menu_item_id,
    :price,
    :menu_description_cs,
    :menu_description_en,
    :menu_is_new,
    :menu_item_is_new,
    :menu_is_visible,
    :menu_item_is_visible,
    :is_numbered,
    :numbering_per_category,
    :ignore_numbering,
    :item_title_cs,
    :item_title_en,
    :desc_cs,
    :desc_en,
    :allergens,
    :vegetarian,
    :spiciness
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %MyApp.Database.Models.ToggleMenuVisibilityItem{}
end