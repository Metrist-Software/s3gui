defmodule S3GuiData.S3ManagerTest do
  use S3GuiData.DataCase

  alias S3GuiData.S3Manager

  alias S3GuiData.Accounts.{User, UserGroup}

  describe "valid_path/2" do
    setup do
      %{ user: %User{
        id: "test-id",
        groups: [
          %UserGroup{ name: "group1" },
          %UserGroup{ name: "group 2" },
        ]
      }}
    end

    test "Returns invalid for path not in user groups, user dir, or public dropbox", %{
      user: user
    } do
      {:error, :invalid_path} = S3Manager.valid_path?(user, "/not-valid")
    end

    test "Returns valid for org dropbox path", %{
      user: user
    } do
      :ok = S3Manager.valid_path?(user, S3Manager.dropbox_prefix())
    end

    test "Returns valid for group in user groups", %{
      user: user
    } do
      :ok = S3Manager.valid_path?(user, "/group 2/")
    end

    test "Returns valid for any user relative path", %{
      user: user
    } do
      :ok = S3Manager.valid_path?(user, "group 2/test.txt")
    end

  end
end
