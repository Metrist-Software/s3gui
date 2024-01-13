defmodule S3GuiWeb.InitAssigns do
  use S3GuiWeb, :live_view

  require Logger

  def on_mount(user_type, _params, session, socket) do
    socket = copy_session(socket, session)

    if validate_user_type(user_type, socket) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: redirect_path(user_type))}
    end
  end

  def render(assigns) do
    ~H""
  end

  # Sharing assigns here so that we don't have to reload the user
  # See https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#assign_new/3-sharing-assigns
  # This will still load the user on the second hit though, can't avoid that https://elixirforum.com/t/liveview-merge-assigns-from-conn-to-socket/30480/2
  # But it will save the second load when the plugs run
  defp copy_session(socket, session) do
    socket
    |> assign_new(:current_user, fn ->
      if session["user_id"] do
        Logger.info("Loading user in init_assigns")
        S3GuiData.Accounts.get_user!(session["user_id"])
      else
        nil
      end
    end)
    |> assign_new(:active_idp, fn -> session["active_idp"] end)
  end

  defp validate_user_type(:user, %{assigns: %{current_user: %{id: _id}}}),
    do: true

  defp validate_user_type(:public, %{assigns: %{current_user: nil}}),
    do: true

  defp validate_user_type(_, _) do
    false
  end

  def redirect_path(:user), do: "/"
end
