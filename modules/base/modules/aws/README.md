# Overview

This module will be called upon by the root module to create the base infrastructure that an engineer can use to provision reproduction environments within their individual AWS sandbox accounts. This configuration creates the following resources:

- An instance profile and IAM role for use with SSM, with associated policies, security group
- A VPC with
	- Default database, public, private, and elasticache subnets, with the option to create additional subnet types
	- Configurable CIDR
	- DNS support
	- Endpoints enabled: EC2 messages, SSM, S3, SSM messages
- An AWS KMS key with a policy that allows the SSM role to decrypt
- Any number of general-use S3 buckets (for non-reproduction-specific items like Terraform Enterprise licenses, airgap files, etc.) with encryption enabled
- Private, public, database, and elasticache subnets

## Contributing

As with any of our internal projects, pull requests absolutely are welcome. Please note that this repository will control the base infrastructure for every engineer's reproduction environment, so please do not commit straight to `main`; go through the proper pull request + review process.
