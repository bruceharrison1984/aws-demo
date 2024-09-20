## wiz-demo
- run terraform templates

## Special Reqs
- Mongo VM has AWS Admin permissions
- Tasky pods have `cluster-admin` permissions

## Issues
- Passing of Mongo connection string is direct via Environment variable
    - In production, this would be sourced via SSM parameter store
- ALB isn't cleaned up after TF destroy
    - This is because it is created by EKS
    - In production, the ALB would be manually created and we would assign necessary annotations to K8s resources to facilitate the connection
      - Or we simply don't worry about this, since we wouldn't ever want to fully destroy the environment
