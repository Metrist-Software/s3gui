defmodule S3GuiData.Repo.Migrations.AddCustomerIdToIdentityProvider do
  use Ecto.Migration

  def change do
    alter table(:identity_providers) do
      add :customer_provided_id, :string
    end

    create unique_index(:identity_providers, [:customer_provided_id])
  end
end
