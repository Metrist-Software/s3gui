defmodule S3GuiWeb.Router do
  use S3GuiWeb, :router

  require Logger

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :set_user
    plug :put_root_layout, {S3GuiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_user do
    plug :require_user_plug
  end

  pipeline :require_admin_user do
    plug :require_admin_user_plug
  end

  pipeline :require_no_user do
    plug :require_no_user_plug
  end

  pipeline :require_aws_account do
    plug :require_aws_account_plug
  end

  scope "/sso" do
    forward "/", Samly.Router
  end

  scope "/" do
    pipe_through :browser
    get "/logout", S3GuiWeb.Controllers.AuthController, :signout
    get "/share/:share_id", S3GuiWeb.Controllers.ShareController, :index
  end

  scope "/", S3GuiWeb do
    pipe_through :browser
    pipe_through :require_no_user

    live_session :public, on_mount: {S3GuiWeb.InitAssigns, :public} do
      live "/login", Live.Login
      live "/login/:customer_provided_id/", Live.Login, :sso_login
      live "/getting-started/", GettingStartedLive.Index, :new
      live "/getting-started/:idp_id/", GettingStartedLive.Index, :login_from_idp
    end
  end

  scope "/aws-setup", S3GuiWeb do
    pipe_through :browser
    pipe_through :require_user

    live_session :user_noaws, on_mount: {S3GuiWeb.InitAssigns, :user} do
      live "/", AwsSetupLive
    end

    get "/install-script/", Controllers.InstallScriptController, :index
  end

  scope "/", S3GuiWeb do
    pipe_through :browser
    pipe_through :require_user
    pipe_through :require_aws_account

    live_session :user, on_mount: {S3GuiWeb.InitAssigns, :user} do
      live "/", Live.Home, :index
      live "/folder/*folder", Live.Home, :index
      live "/group/:group/", Live.Home, :group
      live "/group/:group/folder/*folder", Live.Home, :group
    end
  end

  scope "/", S3GuiWeb do
    pipe_through :browser
    pipe_through :require_admin_user

    live_session :admin_user, on_mount: {S3GuiWeb.InitAssigns, :admin_user} do
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", S3GuiWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:s3gui, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: S3GuiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  def require_user_plug(conn, _opts) do
    user = conn.assigns.current_user

    if is_nil(user) do
      redirect_to_login(conn)
    else
      conn
    end
  end

  def require_admin_user_plug(conn, _opts) do
    #user = conn.assigns.current_user

    # TODO implement
    redirect_to_login(conn)
  end

  def set_user(conn, _opts) do
    assertion = Samly.get_active_assertion(conn) || %{}
    user_id =
      assertion
      |> Map.get(:computed, %{})
      |> Map.get(:user_id)

    case is_nil(user_id) do
      true ->
        conn
        |> assign(:current_user, nil)
      false ->
        Logger.info("Loaded user in router and set in assign")
        user =
          user_id
          |> S3GuiData.Accounts.get_user!([:account])

        conn
        |> put_session(:user_id, user.id)
        |> put_session(:active_idp, assertion.idp_id)
        |> assign(:current_user, user)
    end
  end

  def require_no_user_plug(conn, _opts) do
    user = conn.assigns.current_user

    case user do
      nil ->
        conn

      _user ->
        redirect_to_index(conn)
    end
  end

  def require_aws_account_plug(conn, _opts) do
    user = conn.assigns.current_user

    case user.account.aws_setup_confirmed do
      false ->
        redirect_to_aws_account_setup(conn)

      true ->
        conn
    end
  end

  defp redirect_to_login(conn) do
    conn
    |> redirect(to: "/login")
    |> halt()
  end

  defp redirect_to_index(conn) do
    conn
    |> redirect(to: "/")
    |> halt()
  end

  defp redirect_to_aws_account_setup(conn) do
    conn
    |> redirect(to: "/aws-setup")
    |> halt()
  end

end
