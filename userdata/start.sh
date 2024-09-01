#!/bin/bash

echo '- Get Admin Password'
MONGO_ADMIN_PASS="$(grep -oP "\'.*\'" /home/bitnami/bitnami_credentials | awk '{ print $NF }' | sed "s/'//g")"

echo '- Create Tasky DB'
/home/bitnami/stack/mongodb/bin/mongosh -u root -p $MONGO_ADMIN_PASS --eval "use go-mongodb"
echo '- Finished creating DB'

echo 'Setting User Credentials'
USERNAME=$(aws ssm get-parameter --name "${SSM_USERNAME_PATH}" --query "Parameter.Value" --output text --region us-east-1 --with-decryption)
PASSWORD=$(aws ssm get-parameter --name "${SSM_PASSWORD_PATH}" --query "Parameter.Value" --output text --region us-east-1 --with-decryption)

echo "$USERNAME : $PASSWORD"

/home/bitnami/stack/mongodb/bin/mongosh -u root -p $MONGO_ADMIN_PASS --eval "db.createUser({ user: '$USERNAME', pwd: '$PASSWORD', roles: [{ role: 'readWrite', db: 'go-mongodb' }, { role: 'read', db: 'reporting' }] })"
echo '- Finished setting credentials'
