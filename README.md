# EctoGen

This tool is for `Postgres` database. It is designed for database-first approach. When executed, it generates `DbContext` module with configured module prefix with elixir functions that call db stored procedures.
The generated code even contains parsing mechanism that generates `struct`s for each "complex" type returned from db functions. It even supports procedures (with no return type), functions returning simple types (int, text etc.).
Generated code has no runtime overhead - the code purely uses `Ecto` repo.

The tool uses EEx so it is also quite customizable.
You are able to select just the functions you need from given schemas or you can include all and exclude just some.

## Installation

The package can be installed
by adding `ecto_gen` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_gen, "~> 0.7.1", runtime: false, only: :dev}
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
    db_module: "/path/to/db_module.ex.eex",
    routine: "/path/to/db_routine.ex.eex",
    routine_result: "/path/to/db_routine_result.ex.eex",
    routine_parser: "/path/to/db_routine_parser.ex.eex"
  ],

  # This config holds information about what routines (funcs) from database will have generated elixir functions etc.
  # db project has keys, each representing database's schema which has config for what routines it includes/ingores
  db_project: [
    public: [
      funcs: "*", # or ["func_name_1", "func_name_2"]

      # makes sense to specify ignored functions (routines) only when funcs equal "*"
      ignored_funcs: ["ignored_func_name_1"]
    ]
  ]
```

### Generating the DbContext

With this added to your configuration, you can generate the db context issuing following command:
`$ mix eg.gen`

### Using generated DbContext

Using generated functions is straightforward. Simply call the function to get results:
The Ecto repo must be started.
```elixir
MyApp.EctoGenOutput.DbContext.func_name_1(arg1, arg2)
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ecto_gen](https://hexdocs.pm/ecto_gen).

