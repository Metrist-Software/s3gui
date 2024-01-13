defmodule S3GuiData.Accounts.UserGroup do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_groups" do
    field :name, :string

    belongs_to :user, S3GuiData.Accounts.User, foreign_key: :user_id, references: :id, type: :binary_id

    timestamps()
  end



  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_name()
  end

  @doc false
  def validate_name(changeset) do
    %{changes: changes} = changeset
    case Map.get(changes, :name) do
      nil -> changeset # No change for name in the changeset
      name ->
        changeset
        |> put_change(:name, Regex.replace(S3GuiData.Aws.S3Helper.invalid_character_regex(), name, "-"))
    end
  end
end
