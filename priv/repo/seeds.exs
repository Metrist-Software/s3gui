# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     S3GuiData.Repo.insert!(%S3GuiData.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

require Logger

# Default here is just a sample valid SAML metadata definition without public keys.
# See README.md on how o update this with your local version with your local public keys
# Grab the IDP etadata from SimpleSAMLPHP
local_metadata = HTTPoison.get!("http://localhost:4543/simplesaml/saml2/idp/metadata.php").body

alias S3GuiData.Accounts
alias S3GuiData.Repo

main_account_user_id = "3def3219-7c38-42a5-9fd5-22e8a4fcbf1e"

account =
  %Accounts.Account{
    id: "80b3be65-44d5-43e2-89ba-01422d418ed7",
    name: "Local Dev Account",
    aws_account_id: "046400679278",
    aws_region: "us-west-2",
    aws_setup_confirmed: true
  }
  |> Repo.insert!()

Logger.info("Creating identity provider")


%Accounts.IdentityProvider {
  id: "76e3dfc5-bb6f-43d9-ba37-ed0d458252cd",
  metadata: local_metadata,
  sign_requests: false,
  sign_metadata: false,
  signed_assertion_in_resp: false,
  signed_envelopes_in_resp: false,
  account_id: account.id,
  customer_provided_id: "local"
}
|> Repo.insert!()

Logger.info("Creating user with account id #{account.id}")
%Accounts.User{
  id: "3781dd68-8761-4010-9261-4be94bd213bc",
  email: "test@metrist.io",
  account_id: account.id
} |> Repo.insert!()

%Accounts.User{
  id: main_account_user_id,
  email: "user1@example.com",
  account_id: account.id
} |> Repo.insert!()

# Make user1 the owner
Ecto.Changeset.change(account, owner_id: main_account_user_id)
|> Repo.update!()

# Setup second account with no AWS configuration done and no users
account2 =
  %Accounts.Account{
    id: "f90512e8-4444-4988-9bf7-3da6f88dfc7b",
    name: "Local Dev Account - No AWS or Users",
  }
  |> Repo.insert!()

Logger.info("Creating identity provider")


%Accounts.IdentityProvider {
id: "7fe4fa56-a642-40ac-9e98-bcf6c91be1b3",
metadata: local_metadata,
sign_requests: false,
sign_metadata: false,
signed_assertion_in_resp: false,
signed_envelopes_in_resp: false,
account_id: account2.id,
customer_provided_id: "local2"
}
|> Repo.insert!()
