defmodule S3GuiData.Repo.Migrations.AddAwsBucketSetupConfirmed do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :aws_bucket_setup_confirmed, :boolean, default: false
    end
  end
end
