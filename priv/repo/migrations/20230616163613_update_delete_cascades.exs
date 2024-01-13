defmodule S3GuiData.Repo.Migrations.UpdateDeleteCascades do
  use Ecto.Migration

  # When accounts are deleted, the following references can also be deleted
  def change do
    drop constraint(:identity_providers, "identity_providers_account_id_fkey")
    alter table(:identity_providers) do
      modify :account_id, references(:accounts, on_delete: :delete_all, type: :binary_id)
    end

    drop constraint(:users, "users_account_id_fkey")
    alter table(:users) do
      modify :account_id, references(:accounts, on_delete: :delete_all, type: :binary_id)
    end

    drop constraint(:share_urls, "share_urls_user_id_fkey")
    alter table(:share_urls) do
      modify :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
    end
  end
end
