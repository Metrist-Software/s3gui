defmodule S3GuiData.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :name, :string
    field :owner_id, :binary_id
    field :aws_account_id, :string
    field :aws_region, :string
    field :aws_setup_confirmed, :boolean
    field :aws_bucket_setup_confirmed, :boolean

    has_many :identity_providers, S3GuiData.Accounts.IdentityProvider

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :aws_account_id, :owner_id, :aws_region, :aws_setup_confirmed, :aws_bucket_setup_confirmed])
  end

  @doc false
  def aws_info_changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :aws_account_id, :owner_id, :aws_region, :aws_setup_confirmed, :aws_bucket_setup_confirmed])
    |> validate_required([:aws_account_id, :aws_region])
    |> validate_format(:aws_account_id, ~r/^[0-9]{12}$/)
    |> validate_region()
    |> maybe_setup_aws_setup_flag()
  end

  @doc false
  def validate_region(changeset) do
    validate_change(changeset, :aws_region, fn :aws_region, value ->
      case value in S3GuiData.Aws.Regions.regions() do
        true ->
          []
        false ->
          [aws_region: "Invalid AWS region."]
      end
    end)
  end

  # Reset aws_setup_confirmed to false if region or account id changes
  # They have to reverify
  defp maybe_setup_aws_setup_flag(changeset)
    when is_map_key(changeset.changes, :aws_account_id) or is_map_key(changeset.changes, :aws_region) do
    changeset
    |> Ecto.Changeset.put_change(:aws_setup_confirmed, false)
    |> Ecto.Changeset.put_change(:aws_bucket_setup_confirmed, false)
  end
  defp maybe_setup_aws_setup_flag(changeset), do: changeset
end
