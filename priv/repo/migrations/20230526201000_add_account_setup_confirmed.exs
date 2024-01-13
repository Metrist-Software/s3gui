defmodule S3GuiData.Repo.Migrations.AddAccountSetupConfirmed do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :aws_setup_confirmed, :boolean, default: false
    end
  end
end
