defmodule S3GuiData.Repo do
  use Ecto.Repo,
    otp_app: :s3gui,
    adapter: Ecto.Adapters.Postgres
end
