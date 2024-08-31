# Introduction

This no-code module will provision an installation of Terraform Enterprise that will be deployed within AWS EKS

## Prerequisites

- You're a member of our team's organization in TFC, `team-rts`

  - If you do not have access, reach out in the `#pteam-rts` Slack channel to request to be added.

- You have [Doormat-cli installed](https://github.com/hashicorp/doormat-cli/releases/)

- You have [AWS CLI](https://aws.amazon.com/cli/) installed within your workstation

- You have utilized the `rts-tfe-base-infrastructure` module ([Private Module Registry](https://app.terraform.io/app/team-rts/registry/modules/private/team-rts/rts-tfe-base-infrastructure/aws) | [Github Repository](https://github.com/hashicorp-services/terraform-aws-rts-tfe-base-infrastructure)) to provision the necessary base infrastructure that's needed by this module to deploy successfully through a workspace within our team's organization in TFC, `team-rts`
  * Please follow the readme for the base infrastructure module first before attempting to deploy this module


## Steps to Perform

1. [Log in to TFC](https://app.terraform.io/), and choose the `team-rts` organization.

2. Go to the Registry section of TFC and check the box `No-Code Ready` to only show no-code modules

3. Select the module called `rts-tfe-fdo-eks`

4. Select **Provision workspace**

5. Provide values for the variables you're prompted about, then select **Next: Workspace settings**

6. Provide a name for the workspace that follows this syntax: `tfe-aws-fdo-eks-<first_name_initial><last_name>` or whatever you'd prefer
     * The name must be unique to the organization

7. Select your personal project

8. Select **Create Workspace**
    * A run will automatically be triggered but will fail if you've created the workspace in a project that does not have a variable set within it to supply AWS credentials

9. Push AWS credentials to your new workspace through the use of `doormat` by using the command below:
   * find the value for each of the inserts below by viewing metadata about the AWS account you want to use through the doormat UI at https://doormat.hashicorp.services/
      - Windows:
    
        ```
        doormat aws tf-push `
        --role arn:aws:iam::<ACCOUNT_ID>:role/<ACCOUNT_NAME>-<ACCESS_LEVEL> `
        --organization team-rts `
        --workspace <YOUR_NEW_WORKSPACE_NAME>
        ```
    
     - Linux/Mac:
    
        ```
        doormat aws tf-push \
        --role arn:aws:iam::<ACCOUNT_ID>:role/<ACCOUNT_NAME>-<ACCESS_LEVEL> \
        --organization team-rts \
        --workspace <YOUR_NEW_WORKSPACE_NAME>
        ```

10. Towards the top-right of the workspace overview page, select **New run**, then **Start run**
     * If any errors are reported during the initial run, check that the requirements have been met and if all else fails reach out in our team's private slack channel if you are a member of our team.
      
11. After a successful run has been executed, locate useful information regarding the installation that was provisioned within the _Outputs_ section of the Workspace Overview
      * Running the commands that are shown within the outputs section on your local machine in the numbered order will configure your local access to the Kubernetes cluster and set up the initial admin user for the Terraform Enterprise application.

### Notes to Consider

   * If you need to SSH into your TFE instance(s), you can through the use of `doormat` by executing the command below within your terminal, which will provide a list of instances within the specified region:

       ```doormat session --account <aws_account_name> --region <aws_region>```

# Contributing

Contributions to this repository are very much welcomed! If you'd like to contribute, please make sure that you are not contributing directly to `main`, and are instead going through the appropriate pull request, review, and then merge workflow.