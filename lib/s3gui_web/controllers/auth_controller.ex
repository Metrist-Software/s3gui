defmodule S3GuiWeb.Controllers.AuthController do
  use S3GuiWeb, :controller

  require Logger

  def signout(conn, _params) do
    active_idp = get_session(conn, "active_idp")
    idp_data = Samly.Helper.get_idp(active_idp)
    # We use single sign out when it's available, otherwise we just sign out of s3gui.
    # As an example, google workspace does not provide a SingleLogoutService binding in their metadata
    if idp_data.slo_redirect_url == nil && idp_data.slo_post_url == nil do
      Logger.info("idp id #{active_idp} does not support single sign out. Signing out of S3Gui only.")
      conn
      |> clear_session()
      |> redirect(to: "/")
    else
      conn
      |> redirect(to: "/sso/auth/signout/#{active_idp}")
    end
  end
end
