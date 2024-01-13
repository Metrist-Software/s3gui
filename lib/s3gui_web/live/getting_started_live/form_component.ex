defmodule S3GuiWeb.GettingStarted.FormComponent do
  use S3GuiWeb, :live_component

  alias S3GuiData.Accounts
  require Logger

  @idp_instructions %{
    "Google Workspace" => "https://apps.google.com/supportwidget/articlehome?hl=en&article_url=https%3A%2F%2Fsupport.google.com%2Fa%2Fanswer%2F6087519%3Fhl%3Den&assistant_id=generic-unu&product_context=6087519&product_name=UnuFlow&trigger_context=a",
    "Azure AD" => "https://learn.microsoft.com/en-us/azure/active-directory/manage-apps/add-application-portal-setup-sso",
    "Okta" => "https://support.okta.com/help/s/article/How-To-Configure-A-Custom-SAML-App?language=en_US",
    "Other" => nil
  }

  @impl true
  def mount(socket) do
    {:ok,
    socket
    |> assign(:selected_idp, nil)
    |> allow_upload(:metadata, accept: ~w(.txt .xml), max_entries: 1, max_file_size: 20_000_000)
    }
  end

  @impl true
  def render(assigns) do

    assigns =
      assigns
      |> assign(:idp_instructions, @idp_instructions)

    ~H"""
    <div>
        <.p class="mb-10 font-bold">Note: You must have permission to setup a SAML app and download your identity providers SAML 2.0 metadata to complete this setup.</.p>
        <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself} id="getting-started-form" class="space-y-3">
        <.field type="text" field={@form[:customer_provided_id]} label="An identifier you would like to use to sign in to your organization which will appear in your custom login url." />

        <.field
          field={@form[:idp_select]}
          label="Select your identity provider"
          type="select"
          prompt="--- Please select ---"
          class="w-full"
          options={@idp_instructions |> Enum.map(fn {idp, _instructions} -> idp end)}
          phx-change="choose-idp" />

        <%= if not is_nil(@selected_idp) do %>
          <.p class="" :if={ not is_nil(@idp_instructions[@selected_idp])}>You can follow the instructions <.link href={@idp_instructions[@selected_idp]} target="_blank">here</.link> to assist in the setup</.p>

          <div class="">Please setup your identity provider with the following values:</div>

          <div class="font-bold">Assertion Consumer Service URL:</div><div class="ml-5 mr-5">
          <.clipboard_input
            id="acs_url"
            text={"#{S3GuiWeb.Endpoint.url()}/sso/sp/consume/#{@identity_provider.id}"}
            class="flex flex-row items-center"
            input_container_class="flex-1" />
          </div>
          <div class="font-bold">Entity ID:</div><div class="ml-5 mr-5">
          <.clipboard_input
            id="entity_id"
            text={"#{S3GuiWeb.Endpoint.url()}/sso/sp/metadata/#{@identity_provider.id}"}
            class="flex flex-row items-center"
            input_container_class="flex-1" />
          </div>
          <div class="font-bold">Service Provider Single Logout URL (HTTP-POST only):</div><div class="ml-5 mr-5">
          <.clipboard_input
            id="sso_url"
            text={"#{S3GuiWeb.Endpoint.url()}/sso/sp/logout/#{@identity_provider.id}"}
            class="flex flex-row items-center"
            input_container_class="flex-1" />
          </div>
          <div class="">Please ensure an <span class="font-bold">email</span> attribute is mapped to the users email address in your idp setup.</div>


          <.field_label class="">Upload your SAML 2.0 compliant metadata from your IDP</.field_label>
          <.live_file_input upload={@uploads.metadata} />
          <.progress
                size="xl"
                color="primary"
                value={get_metadata_progress(@uploads.metadata.entries)}
                max={100}
                label={"#{get_metadata_progress(@uploads.metadata.entries)}%"}
                class="flex-grow"
              />
          <%= for err <- translate_errors(@form.errors, :metadata) do %>
            <div class="text-red-500"><%= "#{err}" %></div>
          <% end %>
          <%= if not Enum.empty?(@uploads.metadata.entries) do %>
            <%= for err <- upload_errors(@uploads.metadata, Enum.at(@uploads.metadata.entries, 0)) do %>
              <p class="text-red-500"><%= "#{inspect err}" %></p>
            <% end %>
          <% end %>

          <div class="">
            <.button phx-disable-with="Saving..." label="Next" />
          </div>
        <% end %>
        </.form>
    </div>
    """
  end

  defp get_metadata_progress([]), do: 0
  defp get_metadata_progress(entries), do: Enum.at(entries, 0).progress

  @impl true
  def update(%{identity_provider: identity_provider} = assigns, socket) do
    changeset = Accounts.change_identity_provider(identity_provider)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"identity_provider" => identity_provider_params}, socket) do
    changeset =
      socket.assigns.identity_provider
      |> Accounts.change_identity_provider(identity_provider_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"identity_provider" => identity_provider_params}, socket) do
    metadata =
      consume_uploaded_entries(socket, :metadata, fn %{path: path}, _entry ->
        {:ok, File.read!(path)}
      end)
      |> List.first(:required)

    cond do
      metadata == :required ->
        changeset =
          socket.assigns.identity_provider
          |> Accounts.change_identity_provider(identity_provider_params)
          |> Ecto.Changeset.add_error(:metadata, "You must provide your IDP generated SAML 2.0 Metadata.")
          |> Map.put(:action, :validate)

        {:noreply, assign_form(socket, changeset)}
      true ->
        create_identity_provider(
          socket,
          identity_provider_params
          |> Map.put("metadata", metadata)
        )
    end
  end

  def handle_event("choose-idp", %{"identity_provider" => %{ "idp_select" => idp }}, socket) do
    {:noreply,
    socket |> assign(:selected_idp, idp)}
  end

  defp create_identity_provider(socket, identity_provider_params) do
    # Create the identity provider with the already generated ID (as we've used that for entity ID etc.)
    case Accounts.create_identity_provider(identity_provider_params |> Map.put("id", socket.assigns.identity_provider.id )) do
      {:ok, identity_provider} ->
        notify_parent({:saved, identity_provider})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
