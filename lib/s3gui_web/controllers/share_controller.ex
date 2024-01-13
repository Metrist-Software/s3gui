defmodule S3GuiWeb.Controllers.ShareController do
  use S3GuiWeb, :controller
  alias S3GuiData.S3Manager

  require Logger

  def index(conn, %{"share_id" => share_id}) do
    with {:ok, verified_share_id} <- S3GuiWeb.SigningUtils.verify_share_url_id(share_id),
         share_url <- S3Manager.get_share_url(verified_share_id),
         :ok <- validate_share_url(share_url),
         {:ok, download_url} <- S3Manager.download_url(share_url.user, share_url.key) do
    conn
    |> redirect(external: download_url)
    else
      {:error, error} ->
        Logger.warn("Error getting share URL for share_id #{share_id}. Error was: #{inspect error}")
        conn
        |> put_status(:bad_request)
        |> text("Bad request")
    end
  end

  defp validate_share_url(nil), do: {:error, :not_found}
  defp validate_share_url(share_url) do
    if share_url.expiration <= NaiveDateTime.utc_now() do
      {:error, :expired}
    else
      :ok
    end
  end
end
