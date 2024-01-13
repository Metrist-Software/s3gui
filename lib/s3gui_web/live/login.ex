defmodule S3GuiWeb.Live.Login.InvalidIdp do
  defexception message: "invalid idp", plug_status: 404
end

defmodule S3GuiWeb.Live.Login do
  use S3GuiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"customer_provided_id" => customer_id}, _url, %{ assigns: %{ live_action: :sso_login } } = socket) do
    case S3GuiData.Accounts.get_identity_provider_by_customer_id(customer_id) do
      nil -> raise S3GuiWeb.Live.Login.InvalidIdp
      idp -> {:noreply, redirect(socket, to: "/sso/auth/signin/#{idp.id}")}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">

    <.p class="text-center">To login to an existing S3Gui account, please use your specific login URL provided by your administrator or start the login process from your identity provider dashboard.</.p>
    <.p class="text-center">For new users you can get started below!</.p>

    <div class="text-center w-full mt-2"><a href={"/getting-started/"}>Setup a new account</a></div>

    <%= if Application.get_env(:s3gui, :show_local_login) do %>
      <div class="text-center mt-10">
      <div><a href={"/login/local/"}>[DEV] Local IDP login</a></div>
      <div><a href={"/login/local2/"}>[DEV] Local IDP2 login</a></div>
      </div>
    <% end %>

    </div>
    """
  end
end
