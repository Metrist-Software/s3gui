defmodule S3GuiServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting build: #{build_txt()}")
    S3Gui.CertDownloader.download()

    children = [
      # Start the Telemetry supervisor
      S3GuiWeb.Telemetry,
      # Start the Ecto repository
      S3GuiData.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: S3GuiData.PubSub},
      # Start Finch
      {Finch, name: S3GuiData.Finch},
      # Start the Endpoint (http/https)
      S3GuiWeb.Endpoint,
      # Start Samly
      {Samly.Provider, []},
      {Task, &S3GuiServer.Samly.refresh_idps/0}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: S3GuiData.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    S3GuiWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def build_txt() do
    build_txt = Path.join([Application.app_dir(:s3gui), "priv", "static", "build.txt"])
    if File.exists?(build_txt) do
      File.read!(build_txt)
    else
      "(no build file, localdev?)"
    end
  end
end
