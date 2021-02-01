import Config

config :ecto_gen,
  otp_app: :ecto_gen,
  db_config: MyApp.Repo,
  output_location: "eg_output",
  output_module: "MyApp.EctoGenOutput",
  template_overrides: [
    # db_module: "/path/to/db_module.ex.eex",
    # routine: "/path/to/db_routine.ex.eex",
    # routine_result: "/path/to/db_routine_result.ex.eex",
    # routine_parser: "/path/to/db_routine_parser.ex.eex"
  ],
  db_project: [
    public: [
      funcs: "*",
      ignored_funcs: ["create_menu"]
    ]
  ]

import_config "db_config.secret.exs"