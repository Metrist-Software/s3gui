defmodule S3GuiData.UsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `S3GuiData.Users` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, account}  =
      S3GuiData.Accounts.create_account(%{name: "test account name"})
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "test@metrist.io",
        account_id: account.id
      })
      |> S3GuiData.Accounts.create_user()

    user
  end
end
