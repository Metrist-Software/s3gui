defmodule S3GuiData.UsersTest do
  # TODO: Update these auto generated context tests if we want to keep them

  use S3GuiData.DataCase

  alias S3GuiData.Accounts

  describe "users" do
    alias S3GuiData.Accounts.{Account, User}

    import S3GuiData.UsersFixtures

    @invalid_attrs %{email: nil}

    test "create_user/1 with valid data creates a user" do

      assert {:ok, %Account{} = account} = Accounts.create_account()
      valid_attrs = %{email: "some email", account_id: account.id}

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.email == "some email"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:ok, %Account{} = account} = Accounts.create_account()
      attrs =
        %{account_id: account.id}
        |> Enum.into(@invalid_attrs)

      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      update_attrs = %{email: "some updated email"}

      assert {:ok, %User{} = user} = Accounts.update_user(user, update_attrs)
      assert user.email == "some updated email"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
