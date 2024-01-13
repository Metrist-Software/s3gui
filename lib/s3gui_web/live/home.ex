defmodule S3GuiWeb.Live.Home do
  use S3GuiWeb, :live_view

  alias S3GuiData.{Accounts, S3Manager}
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, account} = Accounts.ensure_bucket_setup(socket.assigns.current_user.account)

    {:ok,
     socket
     # Update account in case bucket flags switched on ensure
     |> assign(:current_user, Map.put(socket.assigns.current_user, :account, account))
     |> assign(:files, [])
     |> assign(:folders, [])
     |> assign(:current_prefix, "")
     |> assign(:parent_url, nil)
     |> assign(:selected_key, nil)
     |> assign(:download_url, "")
     |> assign(:share_modal, false)
     |> assign(:create_folder_modal, false)
     |> assign(:current_group, nil)
     |> allow_upload(:files, accept: :any, max_entries: 10, max_file_size: 1_073_741_824, external: &presign_upload/2 )}
  end

  @impl true
  def handle_params(params, _uri, %{ assigns: %{ live_action: :index} } = socket) do
    {:noreply,
     socket
     |> assign(:current_prefix, prefix_from_url(params))
     |> assign(:current_group, nil)
     |> assign_parent_url()
     |> refresh_files()}
  end

  def handle_params(%{ "group" => group } = params, _uri, %{ assigns: %{ live_action: :group } } = socket) do
    prefix = prefix_from_url(params)
    prefix = "/#{group}/#{prefix}"

    {:noreply,
     socket
     |> assign(:current_prefix, prefix)
     |> assign(:current_group, group)
     |> assign_parent_url()
     |> refresh_files()}
  end

  @impl true
  def handle_event("file-set-change", %{"file-select" => ""}, socket) do
    {:noreply, socket |> redirect(to: "/")}
  end

  def handle_event("file-set-change", %{"file-select" => redirect}, socket) do
    {:noreply, socket |> redirect(to: "/group/#{redirect}/")}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    uploads =
      consume_uploaded_entries(socket, :files, fn _fields, entry ->
        {:ok, {:ok, entry.client_name}}
      end)

    if Enum.empty?(uploads) do
      {:noreply, socket}
    else
      upload_errors =
        uploads
        |> Enum.filter(fn {response_code, _name} -> response_code == :error end)

      {:noreply,
      socket
      |> add_upload_flash_message(upload_errors)
      |> refresh_files()
      }
    end
  end

  def handle_event("select-file", %{ "key" => key, "value" => "true" }, socket) do
    {:ok, download_url} = S3Manager.download_url(socket.assigns.current_user, key)
    {:noreply,
    socket
    |> assign(:selected_key, key)
    |> assign(:file_selected, not String.ends_with?(key, "/"))
    |> assign(:download_url, download_url)}
  end

  def handle_event("share", _params, socket) do
    {:noreply, socket |> assign(:share_modal, true)}
  end

  def handle_event("create-folder", _params, socket) do
    {:noreply,
    socket
    |> assign(:create_folder_modal, true)}
  end

  def handle_event("close_modal", _, socket) do
    {:noreply,
    socket
    |> close_modal_assigns()
    }
  end

  def handle_event("select-file", %{ "key" => _key }, socket) do
    {:noreply,
    socket
    |> assign(:selected_key, nil)}
  end

  def handle_event("delete-object", _params, socket) do
    case S3Manager.delete_object(socket.assigns.current_user, socket.assigns.selected_key) do
      {:ok, _result} ->
        {:noreply,
        socket
        |> stream_delete(:files, %{id: socket.assigns.selected_key})
        |> stream_delete(:folders, %{id: socket.assigns.selected_key})
        |> put_flash(:info, "File(s) deleted successfully")
        |> assign(:selected_key, nil)}
      {:error, response} ->
        Logger.warn("Error deleting files for key #{socket.assigns.selected_key} for user #{socket.assigns.current_user.id}. Error is #{inspect response}")
        {:noreply,
        socket
        |> put_flash(:error, "Error deleting file(s)")}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  @impl true
  def handle_info({:refresh, info_message}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, info_message)
      |> close_modal_assigns()
      |> refresh_files()
    }
  end

  def handle_info({:error, error_message}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:error, error_message)
    }
  end

  defp refresh_files(socket) do
    # Avoid loading the data twice, once on the static render and once when connected to the socket
    %{files: files, folders: folders, valid: valid} =
      if connected?(socket) do
        # TODO: Figure out some type of paging here if more than 1000 files in a given prefix ("folder"). For now 1000 is the limit for list_objects_v2 so we just use that
        case S3Manager.list_objects(socket.assigns.current_user, socket.assigns.current_prefix, 1000) do
          {:error, :invalid_path} ->
            %{files: [], folders: [], valid: false}
          {:ok, response} ->
            response
            |> Map.put(:valid, true)
        end
      else
        %{files: [], folders: [], valid: true}
      end

    socket =
      socket
      |> stream(:files, files |> Enum.map(&(Map.put(&1, :id, Map.get(&1, :key)))), reset: true)
      |> stream(:folders, folders |> Enum.map(&(Map.put(&1, :id, Map.get(&1, :key)))), reset: true)

    if not valid do
      socket
      |> put_flash(:error, "Access denied")
      |> redirect(to: "/")
    else
      socket
    end
  end

  defp checkbox_for_key(assigns) do
    ~H"""
    <span @click="document.querySelectorAll('.file-check').forEach(item => { if (item.parentElement != $el) item.checked = false })">
      <.checkbox
        id={"checkbox-#{@key}"}
        class="file-check"
        phx-click="select-file"
        phx-value-key={"#{@key}"}
        checked={@selected_key == @key}
      />
    </span>
    """
  end

  defp add_upload_flash_message(socket, []), do: socket |> put_flash(:info, "All files uploaded successfully")
  defp add_upload_flash_message(socket, errors) do
    error_string =
      errors
      |> Enum.reduce("The following files could not be uploaded: ", fn {:error, name}, acc ->
        acc <> "#{name},"
      end)
      |> String.trim_trailing(",")

    socket
    |> put_flash(:error, error_string)
  end

  defp get_folder_url(current_prefix, group, folder_name) do
    updated_prefix =
      if group != "" do
        current_prefix
        |> String.replace_leading("/#{group}/", "")
      else
        current_prefix
      end

    if updated_prefix == "" do
      "folder/#{folder_name}"
    else
      folder_name
    end
  end

  defp get_parent_url("", _current_group), do: nil
  defp get_parent_url(current_prefix, current_group) do
    parts =
      if not is_nil(current_group) do
        current_prefix
        |> String.replace_leading("/#{current_group}/", "")
      else
        current_prefix
      end
      |> Path.split()


    if length(parts) == 0 do
      nil
    else
      [_head | tail] = Enum.reverse(parts)

      child_path =
        Enum.join(Enum.reverse(tail), "/")
        |> case do
          "" -> "/"
          other -> "/folder/#{other}/"
        end

      if is_nil(current_group) do
        child_path
      else
        "/group/#{current_group}#{child_path}"
      end
    end
  end

  defp prefix_from_url(params) do
    prefix = Enum.join(Map.get(params, "folder", []), "/")
    if prefix != "", do: "#{prefix}/", else: prefix
  end

  defp assign_parent_url(%{ assigns: %{ current_prefix: current_prefix, current_group: group }} = socket) do
    socket
    |> assign(:parent_url, get_parent_url(current_prefix, group))
  end

  defp presign_upload(entry, socket) do
    key = "#{socket.assigns.current_prefix}#{entry.client_name}"

    %{url: url, fields: fields} =
      S3Manager.presigned_post_url(socket.assigns.current_user, key)

    meta = %{uploader: "S3", key: key, url: url, fields: fields}
    {
      :ok, meta,
      socket
    }
  end

  defp file_selected?(nil), do: false
  defp file_selected?(key), do: not String.ends_with?(key, "/")

  defp close_modal_assigns(socket) do
    socket
    |> assign(:share_modal, false)
    |> assign(:create_folder_modal, false)
  end

  defp get_groups(user) do
    [
      {"Your files", ""},
    ]
    |> Enum.concat(Enum.map(user.groups, &({"#{&1.name} dropbox", URI.encode(&1.name)})))
    |> Enum.concat([{"Organization dropbox", "dropbox"}])
  end
end
