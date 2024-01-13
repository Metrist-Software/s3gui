defmodule S3GuiData.Repo.Migrations.AddEmailAccountUniqueConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:email, :account_id])
  end
end
