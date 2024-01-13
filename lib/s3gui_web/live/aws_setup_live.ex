defmodule S3GuiWeb.AwsSetupLive do
  use S3GuiWeb, :live_view
  require Logger

  alias S3GuiData.{Accounts, S3Manager}

  @impl true
  def mount(_params, _session, socket) do
    changeset = Accounts.change_account(socket.assigns.current_user.account)

    {
      :ok,
      socket
      |> assign(:account, Accounts.get_account!(socket.assigns.current_user.account_id))
      |> assign_form(changeset)
    }
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @impl true
  def handle_event("validate", %{"account" => account_params}, socket) do
    changeset =
      socket.assigns.account
      |> Accounts.change_account(account_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"account" => account_params}, socket) do
    case Accounts.update_account_aws_info(socket.assigns.account, account_params) do
      {:ok, account} ->
        {
          :noreply,
          socket
          |> assign(account: account)
          |> assign(current_user: socket.assigns.current_user |> Map.put(:account, account))
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end


  def handle_event("verify-aws-access", _params, socket) do
    with :ok <- ensure_account_access(socket.assigns.current_user.account),
         {:ok, _ensure_aws_role_response} <- Accounts.ensure_aws_role(socket.assigns.current_user),
         {:ok, _bucket_response} <- S3Manager.setup_main_bucket(socket.assigns.account),
         {:ok, _bucket_response} <- S3Manager.ensure_cors_for_bucket(socket.assigns.account) do
      {:ok, account} =
        Accounts.update_account(socket.assigns.account, %{aws_setup_confirmed: true, aws_bucket_setup_confirmed: true})

      {
        :noreply,
        socket
        |> assign(:account, account)
        |> put_flash(:info, "AWS account setup is good!")
      }
    else
      error ->
        Logger.error("Failed to verify aws access with error: #{inspect(error)}")
        {:ok, account} =
          Accounts.update_account(socket.assigns.account, %{aws_setup_confirmed: false})

        {
          :noreply,
          socket
          |> assign(:account, account)
          |> put_flash(:error, "AWS account is not setup properly.")
        }
    end
  end

  defp ensure_account_access(account) do
    if Accounts.validate_aws_access(account) do
      :ok
    else
      {:error, :unauthorized_aws_access}
    end
  end
end
