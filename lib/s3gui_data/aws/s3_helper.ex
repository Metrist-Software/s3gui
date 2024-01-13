defmodule S3GuiData.Aws.S3Helper do
  @moduledoc """
  Module to help with Aws S3 operations. Called by Contexts
  """

  alias S3GuiData.Aws.RoleHelper
  require Logger

  alias ExAws.S3

  @invalid_character_regex ~r/([^0-9a-zA-Z!_.* '()-])+/

  def invalid_character_regex(), do: @invalid_character_regex

  @doc false
  def create_object(aws_account_id, aws_region, account_id, user_id, name_with_prefix, body) do
    with {:ok, request_config} <- RoleHelper.get_user_role_config(aws_account_id, aws_region, user_id) do
      S3.put_object(bucket(account_id), name_with_prefix, body)
      |> ExAws.request(add_region(request_config, aws_region))
    end
  end

  @doc false
  def upload_object(aws_account_id, aws_region, account_id, user_id, name_with_prefix, path) do
    with {:ok, request_config} <- RoleHelper.get_user_role_config(aws_account_id, aws_region, user_id) do
      path
      |> S3.Upload.stream_file()
      |> S3.upload(bucket(account_id), name_with_prefix)
      |> ExAws.request(add_region(request_config, aws_region))
    end
  end

  @doc false
  def delete_object(aws_account_id, aws_region, account_id, user_id, key) do
    with {:ok, request_config} <- RoleHelper.get_user_role_config(aws_account_id, aws_region, user_id) do
      stream = get_stream_for_prefix(aws_account_id, aws_region, account_id, key)
      ExAws.S3.delete_all_objects(bucket(account_id), stream)
      |> ExAws.request(add_region(request_config, aws_region))
    end
  end

  @doc false
  def setup_main_bucket(aws_account_id, aws_region, account_id) do
    with {:ok, request_config} <- RoleHelper.get_admin_role_config(aws_account_id, aws_region) do
      bucket = bucket(account_id)

      S3.head_bucket(bucket)
      |> ExAws.request(add_region(request_config, aws_region))
      |> case do
        {:ok, _} ->
          Logger.info("Bucket #{bucket} already exist on #{aws_region} for account #{aws_account_id}.. Not creating")
          {:ok, :already_exists}
        {:error, {:http_error, 404, _}} ->
          Logger.info("Bucket #{bucket} does not exist on #{aws_region} for account #{aws_account_id}.. Creating")
          S3.put_bucket(bucket, aws_region)
          |> ExAws.request(add_region(request_config, aws_region))
        other -> other
      end
    end
  end

  @doc false
  def list_objects(aws_account_id, aws_region, account_id, prefix, start_after) do
    with {:ok, request_config} <- RoleHelper.get_admin_role_config(aws_account_id, aws_region) do
        opts =
          [prefix: String.trim_leading(prefix, "/"), delimiter: "/"]
          |> with_start_after(start_after)

        S3.list_objects_v2(bucket(account_id), opts)
        |> ExAws.request(add_region(request_config, aws_region))
        |> case do
          {:ok, response} ->
            {:ok, %{
              files:
              Enum.map(response.body.contents, fn file ->
                file
                |> Map.put(:name, String.replace(file.key, opts[:prefix], ""))
              end)
              # We reject an entry that is exactly the same as the prefix. In an empty prefix this will be included, if there are other files under the prefix it will not
              |> Enum.reject(&(&1.key == opts[:prefix])),
              folders: Enum.map(response.body.common_prefixes, fn %{prefix: prefix} ->
                %{
                  key: prefix,
                  name: String.replace(prefix, opts[:prefix], "")
                }
              end)
            }}
          {:error, error} ->
            {:error, error}
        end
    end
  end

  @doc false
  def download_url(aws_account_id, aws_region, account_id, user_id, key) do
    with {:ok, request_config} <- RoleHelper.get_user_role_config(aws_account_id, aws_region, user_id) do
      ExAws.Config.new(:s3, request_config ++ [region: aws_region])
      |> S3.presigned_url(:get, bucket(account_id), key, virtual_host: true, query_params: [{"response-content-disposition", "attachment; #{Path.basename(key)}"}])
    end
  end

  @doc false
  def presigned_post_url(aws_account_id, aws_region, account_id, user_id, name_with_prefix) do
    with {:ok, request_config} <- RoleHelper.get_user_role_config(aws_account_id, aws_region, user_id) do
      ExAws.Config.new(:s3, request_config ++ [region: aws_region])
      |> ExAws.S3.presigned_post(bucket(account_id), String.trim_leading(name_with_prefix, "/"), virtual_host: true)
    end
  end

  defp with_start_after(opts, nil), do: opts
  defp with_start_after(opts, ""), do: opts
  defp with_start_after(opts, start_after), do: opts ++ [start_after: start_after]

  defp bucket(account_id), do: "s3gui-#{account_id}"

  defp add_region(existing_config, aws_region) do
    existing_config ++ [region: aws_region]
  end

  defp get_stream_for_prefix(aws_account_id, aws_region, account_id, prefix) do
    with {:ok, request_config} <- RoleHelper.get_admin_role_config(aws_account_id, aws_region) do
      ExAws.S3.list_objects_v2(bucket(account_id), prefix: prefix) |> ExAws.stream!(add_region(request_config, aws_region)) |> Stream.map(& &1.key)
    end
  end

  def ensure_cors(aws_account_id, aws_region, account_id) do
    with {:ok, request_config} <- RoleHelper.get_admin_role_config(aws_account_id, aws_region) do
      ExAws.S3.put_bucket_cors(bucket(account_id), [
        %{
          allowed_headers: [ "*" ],
          allowed_methods: [ "PUT", "POST" ],
          allowed_origins: [ "*" ],
          exposed_headers: []
        }
      ])
      |> ExAws.request(add_region(request_config, aws_region))
    end
  end
end
