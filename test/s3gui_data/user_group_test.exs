defmodule S3GuiData.UserGroupTest do
  use S3GuiData.DataCase

  alias S3GuiData.Accounts.UserGroup

  describe "user_group" do
    test "Adding a user_group with a name including invalid characters will update those characters to -" do
      changeset =
        %UserGroup{}
        |> UserGroup.changeset(%{name: "group 1/#@23/45"})

      assert changeset.changes.name == "group 1-23-45"
    end
  end
end
