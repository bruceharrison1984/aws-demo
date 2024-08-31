# Introduction

This configuration creates the base infrastructure that an engineer would need to utilize our other modules for provisioning reproduction environments of Terraform Enteprise. At it's core, the root module calls upon it's child module, `aws`, to create the desired resources defined within that module.

This configuration creates the following resources:

- An instance profile and IAM role for use with SSM, with associated policies, security group
- A VPC with
  - Default database, public, private, and elasticache subnets, with the option to create additional subnet types
  - Configurable CIDR
  - DNS support
  - Endpoints enabled: EC2 messages, SSM, S3, SSM messages
- An AWS KMS key with a policy that allows the SSM role to decrypt
- Any number of general-use S3 buckets (for non-reproduction-specific items like Terraform Enterprise licenses, airgap files, etc.) with encryption enabled
- Private, public, database, and elasticache subnets
- Two S3 buckets: one for airgap files, one for license files
- An S3 bucket object in the form of uploading the license found in the [assets](./assets).

## Prerequisites

- You're a member of our team's organization in TFC, `team-rts`

  - If you do not have access, reach out in the `#pteam-rts` Slack channel to request to be added.

- You have [Doormat-cli installed](https://github.com/hashicorp/doormat-cli/releases/)

  - You have [configured Doormat with HCP Terraform credentials](https://docs.prod.secops.hashicorp.services/doormat/cli/aws/#get-credentials-and-upload-them-to-your-tfce-workspace) 

- You have [AWS CLI](https://aws.amazon.com/cli/) installed in your workstation

- You have an individual sandbox account for AWS created through Doormat

- Your individual sandbox account has default hosted zones existing (See steps below for verifying and resolving, if needed)

    1. Go to https://doormat.hashicorp.services/
    
    2. Enter the console of your individual AWS sandbox account
    
    3. Go to the [Hosted zones section of the Route 53 service](https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones?region=us-east-1#), and confirm as to whether you have a hosted zone available that has the name of `<yourname>.sbx.hashicorpdemos.io` or `<yourname>.aws.sbx.hashicorpdemo.com`
    
       * If you do not, please request within the `#proj-cloud-auth` channel in slack for a hosted zone for `.sbx.hashicorpdemos.io` and `.aws.sbx.hashicorpdemo.com` to be created within your AWS account

## Steps to Perform

1. [Log in to TFC](https://app.terraform.io/), and choose the `team-rts` organization.

2. Create a project for yourself within the Projects & workspaces section, if you do not have one already, that is named following this syntax `<first_name_initial><last_name>`.

3. Go to the Registry section of TFC and check the box `No-Code Ready` to only show no-code modules

4. Select the module called `rts-tfe-base-infrastructure-aws`

5. Select **Provision workspace**

6. Provide values for the variables, then select **Next: Workspace settings**

7. Provide a name for the workspace that follows this syntax: `tfe-aws-base-infrastructure-<first_name_initial><last_name>`

8. Select your personal Project

10. Select **Create Workspace**
    * A run will automatically be triggered but will fail if you've created the workspace in a project that does not have a variable set within it to supply AWS credentials

12. Push AWS credentials to your new workspace through the use of `doormat` by using the command below:

    - Windows:

    ```
    doormat aws tf-push `
    --role arn:aws:iam::<YOUR_AWS_ACCOUNT_ID:role/<YOUR_ROLE_NAME> `
    --organization team-rts `
    --workspace <YOUR_NEW_WORKSPACE_NAME
    ```

    - Linux/Mac:

    ```
    doormat aws tf-push \
    --role arn:aws:iam::<YOUR_AWS_ACCOUNT_ID:role/<YOUR_ROLE_NAME> \
    --organization team-rts \
    --workspace <YOUR_NEW_WORKSPACE_NAME
    ```

13. Within the Workspace, go to _Settings_ > _General_, then select the circle for the _Share with all workspaces in this organization_ option that resides under _Remote state sharing_, then select _Save settings_
    * This access will be needed for any of the no-code TFE modules that you may use after creating this base infrastructure.
      
13. Towards the top-right of the workspace overview page, select **New run**, then **Start run**
    * If any errors are reported during the initial run, check that the requirements have been met and if all else fails reach out in our team's private slack channel if you are a member of our team.
      
14. Go back to the Registry section, find the no-code module that matches the type of TFE installation you're wanting to provision, then follow the readme steps within that module's overview page
    
# Contributing

Contributions to this repository are very much welcomed! If you'd like to contribute, please make sure that you are not contributing directly to `main`, and are instead going through the appropriate pull request, review, and then merge workflow.
