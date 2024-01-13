defmodule S3GuiData.Repo.Migrations.CreateIdentityProviders do
  use Ecto.Migration

  def change do
    create table(:identity_providers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :metadata, :text
      add :sign_requests, :boolean
      add :sign_metadata, :boolean
      add :signed_assertion_in_resp, :boolean
      add :signed_envelopes_in_resp, :boolean

      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id)

      timestamps()
    end
  end
end
