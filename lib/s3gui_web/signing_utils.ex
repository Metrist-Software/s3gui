defmodule S3GuiWeb.SigningUtils do
  require Logger

  alias S3GuiData.S3Manager.ShareUrl

  # Signs a share url with the secret_key_base to prevent tampering. Does not encrypt
  def sign_share_url_id(%ShareUrl{id: id}, %NaiveDateTime{} = expiration) do
    expiration_seconds = NaiveDateTime.diff(expiration, NaiveDateTime.utc_now())
    Phoenix.Token.sign(S3GuiWeb.Endpoint, "share id", id, max_age: expiration_seconds)
  end

  # Verify's a share url id and id
  def verify_share_url_id(token) do
    Phoenix.Token.verify(S3GuiWeb.Endpoint, "share id", token)
  end
end
