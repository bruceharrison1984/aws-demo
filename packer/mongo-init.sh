#!/bin/bash

echo '- Wait for MongoDB credentials to exist and MongoDB to start'
tail -fn0 "/home/bitnami/bitnami_credentials" | head -n1

echo '- Get Admin Password'
MONGO_ADMIN_PASS="$(grep -oP "\'.*\'" /home/bitnami/bitnami_credentials | awk '{ print $NF }' | sed "s/'//g")"

echo '- Execute setup script via mongosh'
/home/bitnami/stack/mongodb/bin/mongosh -u root -p $MONGO_ADMIN_PASS --file setup-mongo.js
echo '- Finished running mongosh'
