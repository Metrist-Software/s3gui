# S3gui

Spike for S3 SAAS Gui.

## Permissions

### S3gui access

S3gui has a single assumable admin role that it uses for all other operations. This role is not currently created by S3gui or a S3gui supplied script.
When it is it should be created under the `/s3gui/` role prefix with an inline policy giving it access to the entire S3gui bucket (see storage locations below)
as well as the role iteration/creation/deletion access it would need to list/create/delete roles under the `/s3gui/` role prefix only.

### User access

When a new user signs in through their IDP, a user is created for them
in S3gui and a user specific assumable role is generated in S3 for that user under the `/s3gui/` role prefix. This keeps the role from showing up in console listings.

## Storage locations

Currently all data is stored under a `s3-gui-{s3gui_account_id}` bucket.

Users have their own prefix of `{userid}/` under said bucket.

## Required Permissions

S3gui needs permissions to assume the `s3gui-admin-role` that is setup in other AWS accounts as people use the system.

Whatever is running S3gui should have the following policy applied which allows it to assume the s3gui/ prefixed role
on any account.

```
{
    "Version": "2012-10-17",
    "Statement": {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Resource": "arn:aws:iam::*:role/s3gui/*"
    }
}
```

## AWS accounts

Currently the AWS account ID that we use to "Run the app from" the s3gui-staging account and is auto setup in .envrc for you.

Seeds sets up the AWS account to delegate to as metrist-sandbox for now but it could be anything.
## Local dev

If you have never run this app before run `make dev`. This will pull the docker images needed, start them, and then update
the saml-sp configuration for simplesamlphp to use HTTP post logouts. (Samly only supports that for logout)

A docker compose file is included with this project which will spawn a SimpleSAMLPhp instance on port 4543 on localhost.

The default admin user can be accessed with `admin:secret`
The default users can be accessed with

- `user1:password`
- `user2:password`

To run the app simply use `make run`. The AWS Profile that will be used is setup in .envrc

The seeds file uses specific ID's to setup the default idp and user so that they all work with the SIMPLESAMLPHP instance.

