defmodule S3GuiData.S3Manager do
  @moduledoc """
  Context for S3 actions and any related data we store/hold
  """
  require Logger
  alias S3GuiData.Aws.S3Helper
  alias S3GuiData.Accounts.{User, Account}

  alias S3GuiData.S3Manager.ShareUrl

  import Ecto.Query

  alias S3GuiData.Repo

  @dropbox_prefix "/dropbox/"

  def create_object(%User{} = user, path, body) do
    with :ok <- valid_path?(user, path) do
      S3Helper.create_object(user.account.aws_account_id, user.account.aws_region, user.account.id, user.id, path |> maybe_add_user_prefix(user), body)
    end
  end

  def create_folder(%User{} = user, path) do
    with :ok <- valid_path?(user, path) do
      Logger.info("Creating folder at #{path} for user #{inspect user}")
      S3Helper.create_object(user.account.aws_account_id, user.account.aws_region, user.account.id, user.id, path|> maybe_add_user_prefix(user), "")
    end
  end

  def delete_object(%User{} = user, key) do
    S3Helper.delete_object(user.account.aws_account_id, user.account.aws_region, user.account.id, user.id, key)
  end

  def list_objects(%User{} = user, prefix, max_items, start_from_marker \\ nil) do
    with  :ok <- valid_path?(user, prefix),
          {:ok, response} <- S3Helper.list_objects(user.account.aws_account_id, user.account.aws_region, user.account.id, prefix |> maybe_add_user_prefix(user), start_from_marker) do
      {:ok, Map.put(response, :files, response.files |> Enum.take(max_items))}
    end
  end

  def setup_main_bucket(%Account{ aws_account_id: aws_account_id, aws_region: aws_region, id: account_id}) do
    S3GuiData.Aws.S3Helper.setup_main_bucket(aws_account_id, aws_region, account_id)
  end

  def upload_object(%User{} = user, path, local_path) do
    with :ok <- valid_path?(user, path) do
      S3Helper.upload_object(user.account.aws_account_id, user.account.aws_region, user.account.id, user.id, path |> maybe_add_user_prefix(user), local_path)
    end
  end

  def download_url(%User{} = user, key) do
    S3Helper.download_url(user.account.aws_account_id, user.account.aws_region, user.account.id, user.id, key)
  end

  def ensure_cors_for_bucket(%Account{} = account) do
    S3Helper.ensure_cors(account.aws_account_id, account.aws_region, account.id)
  end

  def presigned_post_url(%User{} = user, path) do
    with :ok <- valid_path?(user, path),
        {:ok, _response} <- ensure_cors_for_bucket(user.account) do
      S3Helper.presigned_post_url(user.account.aws_account_id, user.account.aws_region, user.account.id, user.id, path |> maybe_add_user_prefix(user))
    end
  end

  # We're going to cleanup expired shares on every creation, this way it doesn't grow too larger
  # and we don't need a background job. Expiration is indexed so it should be quick
  def create_share_url(attrs) do
    share_url =
      %ShareUrl{}
      |> ShareUrl.changeset(attrs)

    now = NaiveDateTime.utc_now()
    expired_deletion =
      ShareUrl
      |> where([s], s.expiration <= ^now)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:share_url, share_url)
    |> Ecto.Multi.delete_all(:expired_shares, expired_deletion)
    |> Repo.transaction()
    |> case do
      {:error, :share_url, changeset, _} ->
        {:error, changeset}
      {:ok, %{share_url: share_url}} ->
        {:ok, share_url}
      end
  end
  def get_share_url!(id), do: Repo.get!(ShareUrl, id) |> Repo.preload([user: :account])
  def get_share_url(id) do
    Repo.get(ShareUrl, id) |> Repo.preload([user: :account])
  end

  def dropbox_prefix(), do: @dropbox_prefix

  @doc false
  # Left public for testing
  # Listing has to use the admin role so we MUST verify the passed in path
  # before calling the S3Helper functions (other actions are protected by the users role)
  # /dropbox/ is ok
  # anything that doesn't start with a / other than public or the users groups is ok
  # anything else that starts with a / is not ok
  def valid_path?(%User{} = _user, <<@dropbox_prefix, _rest::binary>>), do: :ok
  def valid_path?(%User{ groups: groups }, <<"/", rest::binary>>) do
    if Enum.any?(groups, fn group -> String.starts_with?(rest, "#{group.name}/") end) do
      :ok
    else
      {:error, :invalid_path}
    end
  end
  def valid_path?(%User{} = _user, _prefix), do: :ok

  @doc false
  # Left public for testing
  def maybe_add_user_prefix(<<"/", _rest::binary>> = path, _user), do: path
  def maybe_add_user_prefix(path, %User{ id: id }), do: "#{user_prefix(id)}#{path}"

  @doc false
  # Left public for testing
  def user_prefix(user_id), do: "#{user_id}/"

end
