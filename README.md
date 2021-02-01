# EctoGen

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_gen` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_gen, "~> 0.1.0"}
  ]
end
```

## Usage

### First

Prepare tool's configuration:

```elixir
config :my_app, MyApp.Repo,
  username: "db_username",
  password: "db_password",
  database: "database",
  hostname: "hostname"

config :ecto_gen,
  otp_app: :my_app,
  db_config: MyApp.Repo,
  output_location: "path/to/generated/output", # relative path should be relative to the project root
  output_module: "MyApp.EctoGenOutput", # Module prefix that will be used for generated content

  # This way, you can provide custom template for individual parts of generation
  # default files are in /priv/templates directory of this package
  template_overrides: [
    # db_module: "/path/to/db_module.ex.eex",
    # routine: "/path/to/db_routine.ex.eex",
    # routine_result: "/path/to/db_routine_result.ex.eex",
    # routine_parser: "/path/to/db_routine_parser.ex.eex"
  ],

  # This config holds information about what routines (funcs) from database will have generated elixir functions etc.
  # db project has keys, each representing database's schema which has config for what routines it includes/ingores
  db_project: [
    public: [
      funcs: "*", # or ["func_name_1", "func_name_2"]

      # makes sense to specify ignored functions (routines) only when funcs equal "*"
      ignored_funcs: ["create_menu"]
    ]
  ]
```

### Generating the DbContext

With this added to your configuration, you can generate the db context issuing following command:
`$ mix eg.gen`

### Using generated DbContext

Before you start using the generated code you need to start `Postgrex` process (all generated functions to use required as a 1st argument the PID of this `Postgrex` process)

```elixir

{:ok, pg_pid} = Postgrex.start_link(db_config)

alias MyApp.EctoGenOutput, as: EG

EG.DbContext.func_name_1(pg_pid, arg1, arg2)


```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ecto_gen](https://hexdocs.pm/ecto_gen).

