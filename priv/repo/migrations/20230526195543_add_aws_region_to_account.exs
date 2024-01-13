defmodule S3GuiData.Repo.Migrations.AddAwsRegionToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :aws_region, :string
    end
  end
end
