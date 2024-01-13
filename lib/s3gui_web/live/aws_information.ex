defmodule S3GuiWeb.AwsInformation do
  use S3GuiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    Get required AWS information here.
    """
  end
end
