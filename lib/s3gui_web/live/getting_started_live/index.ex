defmodule S3GuiWeb.GettingStartedLive.Index do
  use S3GuiWeb, :live_view

  alias S3GuiData.Accounts
  alias S3GuiData.Accounts.IdentityProvider

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:page_title, "Getting started")
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:identity_provider, %IdentityProvider{ id: Ecto.UUID.generate() })
  end

  defp apply_action(socket, :login_from_idp, %{"idp_id" => idp_id}) do
    idp = Accounts.get_identity_provider!(idp_id)
    socket
    |> assign(:identity_provider, idp)
  end

  @impl true
  def handle_info({S3GuiWeb.GettingStarted.FormComponent, {:saved, identity_provider}}, socket) do
    S3GuiServer.Samly.refresh_idps()
    {
      :noreply,
      socket
      |> assign(:identity_provider, identity_provider)
      |> put_flash(:info, "Successfully setup IDP")
      |> push_navigate(to: "/getting-started/#{identity_provider.id}", replace: true)
    }
  end

  defp get_login_url(idp) do
    "#{S3GuiWeb.Endpoint.url()}/login/#{idp.customer_provided_id}"
  end
end
