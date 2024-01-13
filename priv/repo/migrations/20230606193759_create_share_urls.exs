defmodule S3GuiData.Repo.Migrations.CreateShareUrls do
  use Ecto.Migration

  def change do
    create table(:share_urls, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :expiration, :naive_datetime
      add :key, :string

      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:share_urls, [:expiration])
  end
end
