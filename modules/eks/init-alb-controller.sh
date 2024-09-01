#!/bin/bash

echo "Add Helm repo"
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

echo "Get cluster config for $CLUSTER_NAME"
aws eks update-kubeconfig --region us-east-1 --name $CLUSTER_NAME --profile sandbox

echo "Apply CRDs"
kubectl apply -k "github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.8.2/v2_8_2_ingclass.yaml"

echo "Install ALB Helm chart"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=$SERVICE_ACCOUNT_NAME

