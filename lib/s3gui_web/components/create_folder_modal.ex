defmodule S3GuiWeb.CreateFolderModal do
  use Phoenix.LiveComponent

  alias S3GuiData.S3Manager

  use PetalComponents

  @impl true
  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
      |> assign_create_folder_form(changeset_for_create_folder())
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.modal max_width="lg" title="Create folder">
          <.form for={@create_folder_form} id="create-folder-form" phx-submit="save-create-folder" phx-change="validate-create-folder" class="w-full" phx-target={@myself}>
            <.field type="text" field={@create_folder_form[:name]} label="Please name your folder" />
            <div>
              <.button label="Create Folder" />
            </div>
          </.form>
        </.modal>
      </div>
    """
  end

  @impl true
  def handle_event("validate-create-folder", %{"create_folder" => params }, socket) do
    changeset =
      changeset_for_create_folder(params)
      |> Map.put(:action, :validate)

    {:noreply,
    socket
    |> assign_create_folder_form(changeset)
    }
  end

  def handle_event("save-create-folder", %{"create_folder" => params}, socket) do
    changeset =
      changeset_for_create_folder(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      case S3Manager.create_folder(socket.assigns.current_user, "#{socket.assigns.current_prefix}#{params["name"]}/") do
        {:ok, _response} ->
          notify_parent(:refresh, "Folder created successfully")
          {:noreply,
          socket
          }
        {:error, error} ->
          notify_parent(:error, "Folder could not be created #{inspect error}")
          {
            :noreply,
            socket
            |> assign_create_folder_form(changeset)
          }
      end
    else
      {:noreply, assign_create_folder_form(socket, changeset)}
    end
  end

  # No struct here, just UI direct to S3
  defp changeset_for_create_folder(params \\ %{}) do
    data  = %{}
    types = %{name: :string}
    {data, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required(:name)
    |> Ecto.Changeset.validate_format(:name, ~r/^[a-zA-Z0-9 _-]+$/)
    |> Map.put(:action, :validate)
  end

  defp assign_create_folder_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :create_folder_form, to_form(changeset, as: "create_folder"))
  end

  defp notify_parent(type, message) do
    send(self(), {type, message})
  end
end
