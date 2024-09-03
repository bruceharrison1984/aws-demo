#!/bin/bash

echo '- Get Admin Password'
MONGO_ADMIN_PASS="$(grep -oP "\'.*\'" /home/bitnami/bitnami_credentials | awk '{ print $NF }' | sed "s/'//g")"

echo 'Setting User Credentials'
USERNAME=$(aws ssm get-parameter --name "${SSM_USERNAME_PATH}" --query "Parameter.Value" --output text --region us-east-1 --with-decryption)
PASSWORD=$(aws ssm get-parameter --name "${SSM_PASSWORD_PATH}" --query "Parameter.Value" --output text --region us-east-1 --with-decryption)

/home/bitnami/stack/mongodb/bin/mongosh -u root -p $MONGO_ADMIN_PASS --eval "use go-mongodb" --eval "db.createUser({ user: '$USERNAME', pwd: '$PASSWORD', roles: ['readWrite'] })"
echo '- Finished setting credentials'

echo '- Add S3 backup cron'
S3_BUCKET=$(aws ssm get-parameter --name "${S3_PATH}" --query "Parameter.Value" --output text --region us-east-1 --with-decryption)
echo "* * * * * aws s3 cp --recursive /bitnami/mongodb/data/db $S3_BUCKET --region us-east-1" >> s3.cron
crontab s3.cron
crontab -l

echo '- User-data finished'