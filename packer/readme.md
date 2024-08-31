# wiz-demo MongoDB AMI
This uses Packer to build a pre-configured AMI to the specs given

- Mongo 6.0.7
- Debian 11

## Build
- Login to AWS via `aws sso login --profile sandbox`
- Run `packer build mongodb.pkr.hcl`

The AMI will now be available in the target account