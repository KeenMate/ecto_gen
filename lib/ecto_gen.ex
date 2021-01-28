defmodule EctoGen do
  @moduledoc """
  This module concists of logic for introspecting database and creating usable elixir code.
  """

  require Logger

  @doc """
  Used to retrieve information from database and create elixir code based on retrieved informations
  like stored procedures.
  """
  def start(_feeling, _array) do
    config = EctoGen.Configuration.get_config()

    EctoGen.Application.start_link(config)
  end
end
