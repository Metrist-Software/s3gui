defmodule S3GuiWeb.ShareModal do
  use Phoenix.LiveComponent

  alias S3GuiData.S3Manager

  use PetalComponents
  import S3GuiWeb.CoreComponents

  @impl true
  def update(%{ key: key, current_user: current_user } = assigns, socket) do
    expiration = NaiveDateTime.add(NaiveDateTime.utc_now(), 24, :hour)

    with {:ok, share_url} <- S3Manager.create_share_url(
      %{
        user_id: current_user.id,
        expiration: expiration,
        key: key
      }) do
      {:ok,
      socket
      |> assign(assigns)
      |> assign(:share_url, "#{S3GuiWeb.Endpoint.url()}/share/#{S3GuiWeb.SigningUtils.sign_share_url_id(share_url, expiration)}")
      }
    else
      {:error, error} ->
        {:ok,
        socket
        |> assign(assigns)
        |> put_flash(:error, "Can't create share url. #{inspect error}")
        }
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.modal max_width="lg" title="Share">
          <div x-data="{}">
            <.p>Your share url is below</.p>
            <.clipboard_input
              id="share_url"
              text={"#{@share_url}"}
              class="flex flex-row items-center"
              input_container_class="flex-1"
              input_xinit="$el.focus(); $el.select();" />

            <div class="flex justify-end mt-5">
              <.button label="Close" phx-click={PetalComponents.Modal.hide_modal()} />
            </div>
          </div>
        </.modal>
      </div>
    """
  end
end
