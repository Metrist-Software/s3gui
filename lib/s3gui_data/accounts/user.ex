defmodule S3GuiData.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string

    belongs_to :account, S3GuiData.Accounts.Account, foreign_key: :account_id, references: :id, type: :binary_id
    has_many :groups, S3GuiData.Accounts.UserGroup, on_replace: :delete_if_exists

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :account_id])
    |> validate_required([:email])
  end
end
