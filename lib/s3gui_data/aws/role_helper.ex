defmodule S3GuiData.Aws.RoleHelper do
  @moduledoc """
  Module to help with Aws role operations
  """
  require Logger
  import SweetXml

  require Logger

  @user_policy_name "s3gui-user-policy"

  @doc false
  defp get_role_config(role_arn, aws_region, session_id) do
    ExAws.STS.assume_role(role_arn, session_id, [])
    |> ExAws.request(region: aws_region)
    |> case do
      {:ok, response} ->
        {
          :ok,
          [
            access_key_id: response.body.access_key_id,
            secret_access_key: response.body.secret_access_key,
            security_token: response.body.session_token,
            refreshable: false
          ]
        }
      other_response -> other_response
    end
  end
  def get_role_config!(role_arn, aws_region, session_id) do
    {:ok, response} = get_role_config(role_arn, aws_region, session_id)
    response
  end

  @doc false
  def get_user_role_config(aws_account_id, aws_region, user_id) do
    get_role_config("arn:aws:iam::#{aws_account_id}:role/s3gui/#{user_role(user_id)}", aws_region, user_id)
  end

  @doc false
  def get_admin_role_config(aws_account_id, aws_region) do
    get_role_config("arn:aws:iam::#{aws_account_id}:role/s3gui/s3gui-admin-role", aws_region, "_S3GUI_ADMIN_")
  end

  @doc false
  def user_role_exists?(aws_account_id, aws_region, user_id) do
    with {:ok, request_config} <- get_admin_role_config(aws_account_id, aws_region) do
      request_config
      |> list_roles()
      |> Enum.any?(&(&1.name == user_role(user_id)))
    else
      {:error, error} ->
        Logger.warn("Error getting admin role config. Error is #{inspect error}")
        false
    end
  end

  def get_role_policy_for_user(aws_account_id, aws_region, user_id) do
    with {:ok, request_config} <- get_admin_role_config(aws_account_id, aws_region) do
      action = :get_role_policy
      action_string = action |> Atom.to_string |> Macro.camelize
      operation =
            %ExAws.Operation.Query{
            path: "/",
            params: %{"Action" => action_string, "RoleName" => user_role(user_id), "PolicyName" => @user_policy_name, "Version" => "2010-05-08", "PathPrefix" => "/s3gui/"},
            service: :iam,
            action: action
            }

      response = ExAws.request!(operation, request_config)
      response.body |> xpath(
          ~x"//GetRolePolicyResult"l,
          policy_document: ~x"./PolicyDocument/text()"s
      )
    else
      {:error, error} ->
        Logger.warn("Error getting admin role config. Error is #{inspect error}")
        false
    end
  end

  @doc false
  def create_user_role(aws_account_id, account_id, aws_region, user_id, groups) do
    with {:ok, request_config} <- get_admin_role_config(aws_account_id, aws_region) do
      action = :create_role
      action_string = action |> Atom.to_string |> Macro.camelize
      %ExAws.Operation.Query{
      path: "/",
      params: %{
        "Action" => action_string,
        "Version" => "2010-05-08",
        "Path" => "/s3gui/",
        "RoleName" => user_role(user_id),
        "AssumeRolePolicyDocument" => get_role_trust_relationship()
      },
      service: :iam,
      action: action
      }
      |> ExAws.request(request_config)

      add_user_role_policy(aws_account_id, account_id, aws_region, user_id, groups)
    end
  end

  @doc false
  def add_user_role_policy(aws_account_id, account_id, aws_region, user_id, groups, request_config \\ nil) do
    with {:ok, request_config} <- if not is_nil(request_config), do: {:ok, request_config}, else: get_admin_role_config(aws_account_id, aws_region) do
      action = :put_role_policy
      action_string = action |> Atom.to_string |> Macro.camelize

      %ExAws.Operation.Query{
      path: "/",
      params: %{
        "Action" => action_string,
        "Version" => "2010-05-08",
        "RoleName" => user_role(user_id),
        "PolicyName" => @user_policy_name,
        "PolicyDocument" => get_user_role_policy(account_id, user_id, groups)
      },
      service: :iam,
      action: action
      }
      |> ExAws.request(request_config)
    end
  end

  @doc false
  def create_admin_role(aws_account_id) do
    action = :create_role
    action_string = action |> Atom.to_string |> Macro.camelize
    %ExAws.Operation.Query{
    path: "/",
    params: %{
      "Action" => action_string,
      "Version" => "2010-05-08",
      "Path" => "/s3gui/",
      "RoleName" => "s3gui-admin-role",
      "AssumeRolePolicyDocument" => get_role_trust_relationship()
    },
    service: :iam,
    action: action
    }
    |> ExAws.request()

    action = :put_role_policy
    action_string = action |> Atom.to_string |> Macro.camelize

    %ExAws.Operation.Query{
      path: "/",
      params: %{
        "Action" => action_string,
        "Version" => "2010-05-08",
        "RoleName" => "s3gui-admin-role",
        "PolicyName" => "s3gui-admin-policy",
        "PolicyDocument" => get_admin_role_policy(aws_account_id)
      },
      service: :iam,
      action: action
      }
      |> ExAws.request()
  end

  defp list_roles(request_config) do
    action = :list_roles
    action_string = action |> Atom.to_string |> Macro.camelize
    operation =
          %ExAws.Operation.Query{
          path: "/",
          params: %{"Action" => action_string, "Version" => "2010-05-08", "PathPrefix" => "/s3gui/"},
          service: :iam,
          action: action
          }

    response = ExAws.request!(operation, request_config)
    response.body |> xpath(
        ~x"//member"l,
        name: ~x"./RoleName/text()"s,
        arn: ~x"./Arn/text()"s,
        path: ~x"./Path/text()"s
    )
  end

  defp get_user_role_policy(account_id, user_id, groups) do
    #TODO add group access and reduce permissions here (not s3:* like admin)

    """
    {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "S3guiS3",
              "Effect": "Allow",
              "Action": [
                  "s3:*"
              ],
              "Resource": [
                  "arn:aws:s3:::s3gui-#{account_id}/#{user_id}",
                  "arn:aws:s3:::s3gui-#{account_id}/#{user_id}/*",
                  #{get_group_arns(account_id, groups)}
              ]
          },
          {
              "Sid": "S3guiListBuckets",
              "Effect": "Allow",
              "Action": "s3:ListAllMyBuckets",
              "Resource": "*"
          }
        ]
    }
    """
  end

  defp get_group_arns(account_id, groups) do
    ["arn:aws:s3:::s3gui-#{account_id}/dropbox",
    "arn:aws:s3:::s3gui-#{account_id}/dropbox/*"]
    |> Enum.concat(Enum.flat_map(groups, fn group ->
      ["arn:aws:s3:::s3gui-#{account_id}/#{group}",
      "arn:aws:s3:::s3gui-#{account_id}/#{group}/*"]
    end))
    |> Enum.map(&("\"#{&1}\""))
    |> Enum.join(",\n")
  end

  defp get_admin_role_policy(aws_account_id) do
    """
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "S3guiS3",
          "Effect": "Allow",
          "Action": [
              "s3:*"
          ],
          "Resource": [
            "arn:aws:s3:::s3gui-*",
            "arn:aws:s3:::s3gui-*/*"
          ]
        },
        {
          "Sid": "S3guiListBuckets",
          "Effect": "Allow",
          "Action": "s3:ListAllMyBuckets",
          "Resource": [
              "*"
          ]
        },
        {
          "Sid": "S3guiIam",
          "Effect": "Allow",
          "Action": [
              "iam:TagRole",
              "iam:CreateRole",
              "iam:DeleteRole",
              "iam:UpdateRole",
              "iam:ListRoles",
              "iam:GetRole",
              "iam:GetRolePolicy",
              "iam:DeleteRolePolicy",
              "iam:ListRolePolicies",
              "iam:PutRolePolicy",
              "iam:UpdateAssumeRolePolicy",
              "iam:UntagRole"
          ],
          "Resource": [
              "arn:aws:iam::#{aws_account_id}:role/s3gui",
              "arn:aws:iam::#{aws_account_id}:role/s3gui*",
              "arn:aws:iam::#{aws_account_id}:role/s3gui/*"
          ]
        }
      ]
    }
    """
  end

  defp get_role_trust_relationship() do
    """
    {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Principal": {
                  "AWS": "arn:aws:iam::#{Application.get_env(:s3gui, :aws_account_id)}:root"
              },
              "Action": "sts:AssumeRole",
              "Condition": {}
          }
      ]
    }
    """
  end

  defp user_role(user_id), do: "s3gui-user-#{user_id}"
end
