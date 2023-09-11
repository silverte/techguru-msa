#!bin/bash

eksctl utils associate-iam-oidc-provider \
    --cluster eks-eda \
    --approve
    
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export ES_DOMAIN_NAME="eksworkshop-logging"
echo $AWS_REGION
echo $ACCOUNT_ID
echo $ES_DOMAIN_NAME

mkdir ~/environment/logging/

cat <<EoF > ~/environment/logging/fluent-bit-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "es:ESHttp*"
            ],
            "Resource": "arn:aws:es:${AWS_REGION}:${ACCOUNT_ID}:domain/${ES_DOMAIN_NAME}"
        }
    ]
}
EoF

aws iam create-policy   \
  --policy-name fluent-bit-policy \
  --policy-document file://~/environment/logging/fluent-bit-policy.json
  
  
kubectl create namespace logging

eksctl create iamserviceaccount \
    --name fluent-bit \
    --namespace logging \
    --cluster eksworkshop \
    --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/fluent-bit-policy" \
    --approve \
    --override-existing-serviceaccounts


kubectl -n logging describe serviceaccounts fluent-bit
