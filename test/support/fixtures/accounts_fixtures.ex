defmodule S3GuiData.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `S3GuiData.Accounts` context.
  """

  @doc """
  Generate a account.
  """
  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> S3GuiData.Accounts.create_account()

    account
  end
end
