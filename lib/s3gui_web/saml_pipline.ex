defmodule S3GuiWeb.SamlPipline do
  @moduledoc """
  Pipeline that runs upon successful SAML authentication (before session plug)
  """
  use Plug.Builder
  require Logger
  alias Samly.{Assertion}
  alias S3GuiData.Accounts
  alias Samly.Assertion

  plug :jit_user_creation

  def jit_user_creation(conn, _opts) do
    %Assertion{} = assertion = conn.private[:samly_assertion]

    email = Map.get(assertion.attributes, "email")
    groups = Map.get(assertion.attributes, "groups", [])

    # Some IDPs like Google will send groups => "S3gui" if somebody is only in one
    # group and groups => ["group1", "group2"] if there is more than one
    groups = if not is_list(groups) do
      [groups]
    else
      groups
    end

    if is_nil(email) do
      conn
      |> resp(403, "email attribute not mapped in identity provider. Please map the email attribute before continuing.")
      |> halt()
    else
      idp = Accounts.get_identity_provider!(assertion.idp_id, :account)
      user = Accounts.get_user_by_email_and_account(email, idp.account_id)

      user =
        if is_nil(user) do
          {:ok, user} = S3GuiData.Accounts.create_user(%{email: email, account_id: idp.account.id, groups: groups})
          user
        else
          {:ok, user} = S3GuiData.Accounts.update_user(user, %{groups: groups})
          user
        end

      Accounts.ensure_aws_role(user)

      assertion = %Assertion{assertion | computed: %{ user_id: user.id }}

      conn
      |> put_private(:samly_assertion, assertion)
    end
  end
end
