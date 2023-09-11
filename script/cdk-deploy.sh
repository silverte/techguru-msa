#!/bin/bash

export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

# cdk bootstrap
cdk bootstrap --trust=$ACCOUNT_ID --cloudformation-execution-policies arn:aws:iam::aws:policy/AdministratorAccess aws://$ACCOUNT_ID/$AWS_REGION

# deploy stacks
cd ~/environment/techguru-msa
export STAGE="Vpc"
cdk deploy vpc-techguru --require-approval never
export STAGE="Stacks"
cdk deploy "rds-*" "eks-*" "msk-*" --require-approval never --concurrency 10

# csi driver add-on 설치
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster eks-eda \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole
eksctl create addon --name aws-ebs-csi-driver --cluster my-cluster \
  --service-account-role-arn arn:aws:iam::$ACCOUNT_ID:role/AmazonEKS_EBS_CSI_DriverRole --force