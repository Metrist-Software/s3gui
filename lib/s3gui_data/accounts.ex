defmodule S3GuiData.Accounts do
  @moduledoc """
  The Accounts context.
  """

  require Logger

  import Ecto.Query

  alias S3GuiData.{Repo, S3Manager}

  alias S3GuiData.Accounts.Account
  alias S3GuiData.Aws.RoleHelper

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
  end

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id), do: Repo.get!(Account, id)
  def get_account(id) do
    Repo.get(Account, id)
    |> Repo.preload(:identity_providers)
  end

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs, changeset \\ &Account.changeset/2) do
    account
    |> changeset.(attrs)
    |> Repo.update()
  end

  def update_account_aws_info(%Account{} = account, attrs) do
    update_account(account, attrs, &Account.aws_info_changeset/2)
  end


  @doc """
  Deletes a account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end

  alias S3GuiData.Accounts.{User, UserGroup}

  @user_default_preloads [:account, :groups]

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id, preloads \\ []) do
    Repo.get!(User, id)
    |> Repo.preload(@user_default_preloads ++ preloads)
  end

  def get_user_by_email_and_account(email, account_id, preloads \\ []) do
    User
    |> where([u], u.email == ^email and u.account_id == ^account_id)
    |> Repo.one()
    |> Repo.preload(@user_default_preloads ++ preloads)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    account = get_account(attrs[:account_id])

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user,
      %User{}
      |> Repo.preload(:account)
      |> change_user(attrs)
      |> Ecto.Changeset.put_assoc(:account, account)
    )
    |> maybe_set_account_owner_id(account, attrs)
    |> Repo.transaction()
    |> case do
      {:error, :user, changeset, _} ->
        {:error, changeset}
      {:ok, %{user: user}} ->
        {:ok, user}
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> change_user(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    changeset = User.changeset(user, attrs)

    if not is_nil(attrs[:groups]) and is_list(attrs[:groups]) do
      user =
        user
        |> Repo.preload(:groups)

      to_add =
        Enum.filter(attrs[:groups], fn group -> not Enum.any?(user.groups, &(&1.name == group)) end)
        |> Enum.map(fn group -> %UserGroup{ name: group } end)

      updated_groups =
        Enum.filter(user.groups, fn group -> Enum.any?(attrs[:groups], &(&1 == group.name)) end)
        |> Enum.concat(to_add)

      changeset
      |> Ecto.Changeset.put_assoc(:groups, updated_groups)
    else
      changeset
    end
  end

  alias S3GuiData.Accounts.IdentityProvider

  def get_identity_provider!(id, preloads \\ []) do
    Repo.get!(IdentityProvider, id)
    |> Repo.preload(preloads)
  end

  def get_identity_provider_by_customer_id!(customer_id, preloads \\ []) do
    IdentityProvider
    |> where([i], i.customer_provided_id == ^customer_id)
    |> Repo.one!()
    |> Repo.preload(preloads)
  end

  def get_identity_provider_by_customer_id(customer_id, preloads \\ []) do
    IdentityProvider
    |> where([i], i.customer_provided_id == ^customer_id)
    |> Repo.one()
    |> Repo.preload(preloads)
  end

  def list_identity_providers() do
    IdentityProvider
    |> Repo.all()
  end

  @doc """
  Returns all identity providers for an account

  ## Examples

      iex> list_identity_providers_for_account("account_id")
      [%IdentityProvider{}, ...]

  """
  def list_identity_providers_for_account(account_id) do
    IdentityProvider
    |> where([i], i.account_id == ^account_id)
    |> Repo.all()
  end

  @doc """
  When we don't have an account already, create one within the transaction (Ex. Getting-Started)
  """
  def create_identity_provider(attrs) when not is_map_key(attrs, "account_id") do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:account, %Account{})
    |> Ecto.Multi.run(:idp, fn repo, %{account: account} ->
      %IdentityProvider{}
      |> change_identity_provider(attrs)
      |> Ecto.Changeset.put_assoc(:account, account)
      |> repo.insert()
    end)
    |> Repo.transaction()
    |> case do
      {:error, :idp, changeset, _} ->
        {:error, changeset}
      {:ok, %{idp: identity_provider}} ->
        {:ok, identity_provider}
    end
  end

  def create_identity_provider(attrs) do
    %IdentityProvider{}
    |> change_identity_provider(attrs)
    |> Repo.insert()
  end

  def update_identity_provider(%IdentityProvider{} = identity_provider, attrs) do
    identity_provider
    |> change_identity_provider(attrs)
    |> Repo.update()
  end

  def change_identity_provider(%IdentityProvider{} = identity_provider, attrs \\ %{}) do
    changeset = IdentityProvider.changeset(identity_provider, attrs)

    if attrs["id"] do
      changeset
      |> Ecto.Changeset.put_change(:id, attrs["id"])
    else
      changeset
    end
  end

  def ensure_aws_role(%User{ account: %Account{ aws_account_id: nil } = account }) do
    Logger.info("AWS setup not complete for account #{account.id}. Skipping ensure_aws_role check.")
    {:error, :incomplete_account_setup}
  end
  def ensure_aws_role(%User{} = user) do
    if not (RoleHelper.user_role_exists?(user.account.aws_account_id, user.account.aws_region, user.id)) do
      Logger.info("Role for user #{user.id} not found. Creating...")
      case RoleHelper.create_user_role(user.account.aws_account_id, user.account.id, user.account.aws_region, user.id, user.groups |> Enum.map(&(&1.name))) do
        {:ok, result} ->
          Logger.info("Role created successfully")
          {:ok, result}
        {_, result} ->
          Logger.error("Error creating role. Error was #{inspect result}")
          {:error, result}
      end
    else
      Logger.info("Role already exists for #{user.id} in #{user.account.aws_account_id}. Updating it to ensure it is up to date with groups.")
      case RoleHelper.add_user_role_policy(user.account.aws_account_id, user.account.id, user.account.aws_region, user.id, user.groups |> Enum.map(&(&1.name))) do
        {:ok, result} ->
          Logger.info("Role created successfully")
          {:ok, result}
        {_, result} ->
          Logger.error("Error updating role. Error was #{inspect result}")
          {:error, result}
      end
    end
  end

  def validate_aws_access(%Account{ aws_account_id: aws_account_id, aws_region: aws_region }) do
    with {:ok, _response} <- RoleHelper.get_admin_role_config(aws_account_id, aws_region) do
      true
    else
      {:error, response} ->
        Logger.warn("Can't get admin role config for aws_account_id: #{aws_account_id} and aws_region: #{aws_region}. Error: #{inspect response}")
        false
    end
  end

  def ensure_bucket_setup(%Account{ aws_bucket_setup_confirmed: true } = account), do: {:ok, account}
  def ensure_bucket_setup(%Account{} = account) do
    with {:ok, _bucket_response} <- S3Manager.setup_main_bucket(account),
         {:ok, _bucket_response} <- S3Manager.ensure_cors_for_bucket(account) do

      update_account(account, %{aws_bucket_setup_confirmed: true})
    end
  end

  defp maybe_set_account_owner_id(multi, account, attrs)
  defp maybe_set_account_owner_id(multi, %{owner_id: nil} = account, attrs) do
    multi
    |> Ecto.Multi.run(:account, fn repo, %{user: user} ->
      account
      |> Account.changeset(attrs)
      |> Ecto.Changeset.put_change(:owner_id, user.id)
      |> repo.update()
    end)
  end
  defp maybe_set_account_owner_id(multi, _, _attrs), do: multi
end
