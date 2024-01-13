defmodule S3Gui.CertDownloader do
  require Logger

  def download() do
    with :continue <- validate_download_cert(),
         :continue <- validate_file_exists(),
         %{"cert" => cert_base64, "cert_key" => cert_key_base64} <-
           S3GuiData.Secrets.get_secret("service_provider_certkey"),
         :ok <- File.mkdir_p(cert_dir()),
         {:ok, cert} <- Base.decode64(cert_base64),
         {:ok, key} <- Base.decode64(cert_key_base64),
         :ok <- File.write(cert_path(), cert),
         :ok <- File.write(key_path(), key),
         do: :ok
  end

  def validate_file_exists do
    if File.exists?(cert_path()) || File.exists?(key_path()) do
      Logger.info("Skipping cert and key download")
      :ok
    else
      :continue
    end
  end

  def validate_download_cert do
    if Application.get_env(:s3gui, :download_cert, false) do
      :continue
    else
      Logger.info("Skipping cert and key download")
      :ok
    end
  end

  def cert_path, do: Path.join(cert_dir(), "cert.pem")

  def key_path, do: Path.join(cert_dir(), "cert_key.pem")

  defp cert_dir() do
    System.tmp_dir!()
    |> Path.join(["s3gui", "/", "cert"])
  end
end
