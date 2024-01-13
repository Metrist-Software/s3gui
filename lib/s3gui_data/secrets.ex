defmodule S3GuiData.Secrets do
  @moduledoc """
  Simple wrapper around secrets manager
  """
  require Logger

  def get_secret(path) do
    env = System.get_env("MDS_ENV", "localdev")
    region = System.get_env("MDS_REGION", "us-east-2")
    path = "mds/#{env}/s3gui/#{path}"

    result =
      path
      |> ExAws.SecretsManager.get_secret_value()
      |> ExAws.request(region: region)

    case result do
      {:ok, %{"SecretString" => secret}} ->
        Logger.info("Successfully fetched secret '#{path}'")
        Jason.decode!(secret)

      {:error, error} ->
        Logger.error("Error getting secret '#{path}': #{inspect(error)}")
        nil
    end
  end
end
