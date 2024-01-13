defmodule S3GuiData.S3Manager.ShareUrl do
  @moduledoc """
  We store all share URLs for multiple reasons
  1. We can make the share URL whatever we want (for now UUID) and something shorter than the AWS presigned link
  2. Presigned links expire as soon as the credentials that created them expire. In our
     case we use STS with temporary credentials which expire in 1 hour. This allows us
     to have expiry's of greater than an hour without leaving temporary long lasting credentials
     around
  3. Will allow us to do more advanced things in the future such as sharing entire folders which S3 presigned
     urls doesn't support, or downloading multiple files at once (zip), or single use share URLs etc.
  """
  use Ecto.Schema
  import Ecto.Changeset

  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "share_urls" do
    field :expiration, :naive_datetime
    field :key, :string

    belongs_to :user, S3GuiData.Accounts.User, foreign_key: :user_id, references: :id, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(share_url, attrs) do
    share_url
    |> cast(attrs, [:user_id, :expiration, :key])
    |> validate_required([:expiration, :key])
  end
end
