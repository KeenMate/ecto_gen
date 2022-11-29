import Config

config :ecto_gen,
  otp_app: :ecto_gen,
  db_config: MyApp.Repo,
  output_location: "lib/eg_output",
  output_module: "MyApp.Database",
  db_project: [
    public: [
      funcs: [
        "get_import_usernames"
      ]
    ],
    internal: [
      funcs: [
        "handle_sendout_recipient_from_import_result"
      ]
    ]
  ]

File.regular?("config/db_config.secret.exs") && import_config("db_config.secret.exs")
