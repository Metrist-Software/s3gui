import Config

# Configure your database
config :s3gui, S3GuiData.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "s3gui_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

port = (System.get_env("PORT") || "4443") |> String.to_integer()

config :s3gui, S3GuiWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  https: [
    ip: {127, 0, 0, 1},
    port: port,
    cipher_suite: :strong,
    keyfile: "priv/localhost+2-key.pem",
    certfile: "priv/localhost+2.pem"
  ],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "QYB0kwag+zRLK44/Pvaz543cAYWXDdQgWSE6+M8Mpla866bVf1UXiGKXAzesyyg0",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :s3gui, S3GuiWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/s3gui_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :s3gui,
  # Enable dev routes for dashboard and mailbox
  dev_routes: true,
  aws_account_id: System.get_env("S3GUI_AWS_ACCOUNT_ID")

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n", level: :debug

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

config :samly, Samly.State,
  store: Samly.State.Session,
  opts: [key: :samly_assertion]

config :samly, Samly.Provider,
  idp_id_from: :path_segment,
  service_providers: [
    %{
      id: "s3gui-sp",
      certfile: "priv/cert/s3gui_sp.pem",
      keyfile: "priv/cert/s3gui_sp_key.pem"
    }
  ]