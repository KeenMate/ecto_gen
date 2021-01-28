defmodule EctoGen.Application do
  def start_link(config) do
    children = [
      {EctoGen.Database, config.database}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
