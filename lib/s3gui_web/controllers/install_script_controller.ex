defmodule S3GuiWeb.Controllers.InstallScriptController do
  use S3GuiWeb, :controller

  @setup_script_template """
  #! /bin/bash

  set -Eeou pipefail

  trap 'rm -f /tmp/s3gui-*' EXIT

  if [[ ! $(aws sts get-caller-identity) ]]; then
    echo "AWS config not found or CLI is not installed"
    exit 1
  fi

  cat << EOC > /tmp/s3gui-assume-role-policy.json
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<<aws_account_id>>:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
        }
    ]
  }
  EOC

  aws iam create-role --path /s3gui/ --role-name s3gui-admin-role --no-cli-pager --assume-role-policy-document file:///tmp/s3gui-assume-role-policy.json

  cat << EOC > /tmp/s3gui-inline-policy.json
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
            "arn:aws:iam::<<customer_aws_account_id>>:role/s3gui",
            "arn:aws:iam::<<customer_aws_account_id>>:role/s3gui*",
            "arn:aws:iam::<<customer_aws_account_id>>:role/s3gui/*"
        ]
      }
    ]
  }
  EOC

  aws iam put-role-policy --role-name s3gui-admin-role --policy-name s3gui-admin-policy --no-cli-pager --policy-document file:///tmp/s3gui-inline-policy.json


  echo "All set. Please continue with S3Gui setup."
  exit 0
  """

  def index(conn, _params) do
    account = conn.assigns.current_user.account
    setup_script =
      @setup_script_template
      |> String.replace("<<aws_account_id>>", Application.get_env(:s3gui, :aws_account_id))
      |> String.replace("<<customer_aws_account_id>>", account.aws_account_id)

    conn
    |> send_download({:binary, setup_script}, filename: "s3gui-install-script.sh", content_type: "text/plain", charset: "utf-8")
  end

end
