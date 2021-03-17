import Config

config :ecto_gen,
  otp_app: :ecto_gen,
  db_config: MyApp.Repo,
  output_location: "lib/eg_output",
  output_module: "MyApp.Database",
  # template_overrides: [
  #   db_module: "/path/to/db_module.ex.eex",
  #   routine: "/path/to/db_routine.ex.eex",
  #   routine_result: "/path/to/db_routine_result.ex.eex",
  #   routine_parser: "/path/to/db_routine_parser.ex.eex"
  # ],
  db_project: [
    public: [
      funcs: [
        "get_all_menu",
        "toggle_menu_visibility",
        "toggle_menu_new_state",
        "this_is_procedure"
      ]
    ]
  ]

import_config "db_config.secret.exs"
