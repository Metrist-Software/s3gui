defmodule S3GuiData.AccountsTest do
  # TODO: Update these auto generated context tests if we want to keep them

  use S3GuiData.DataCase

  alias S3GuiData.Accounts

  describe "accounts" do
    alias S3GuiData.Accounts.Account

    import S3GuiData.AccountsFixtures

    test "create_account/1 with valid data creates a account" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Account{} = account} = Accounts.create_account(valid_attrs)
      assert account.name == "some name"
    end

    test "update_account/2 with valid data updates the account" do
      account = account_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Account{} = account} = Accounts.update_account(account, update_attrs)
      assert account.name == "some updated name"
    end

    test "delete_account/1 deletes the account" do
      account = account_fixture()
      assert {:ok, %Account{}} = Accounts.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_fixture()
      assert %Ecto.Changeset{} = Accounts.change_account(account)
    end
  end
end
