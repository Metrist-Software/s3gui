defmodule S3GuiData.Accounts.IdentityProvider do
  use Ecto.Schema
  import Ecto.Changeset

  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "identity_providers" do
    field :metadata, :string
    field :sign_requests, :boolean, default: false
    field :sign_metadata, :boolean, default: false
    field :signed_assertion_in_resp, :boolean, default: false
    field :signed_envelopes_in_resp, :boolean, default: false
    field :customer_provided_id, :string

    belongs_to :account, S3GuiData.Accounts.Account, foreign_key: :account_id, references: :id, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(identity_provider, attrs) do
    identity_provider
    |> cast(attrs, [:customer_provided_id, :metadata, :account_id, :sign_requests, :sign_metadata, :signed_assertion_in_resp, :signed_envelopes_in_resp])
    |> unique_constraint(:customer_provided_id)
    |> validate_required([:customer_provided_id])
    |> validate_format(:customer_provided_id, ~r/^[a-zA-Z0-9_-]+$/)
    |> validate_metadata()
  end

  @doc false
  def validate_metadata(changeset) do
    validate_change(changeset, :metadata, fn :metadata, value ->
      case S3GuiWeb.Saml2Validator.validate_string(value, Path.join([:code.priv_dir(:s3gui), "/", "xsds", "/", "saml-schema-metadata-2.0.xsd"])) do
        true ->
          []
        false ->
          [metadata: "The uploaded metadata does not meet SAML2.0 standards."]
      end
    end)
  end
end
