#!bin/bash

ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

role=$(aws sts assume-role --role-arn arn:aws:iam::$ACCOUNT_ID:role/eks-eda-eksedaAccessRoleC97EAB48-WWZBUROHOT23 \
                           --role-session-name AWSCLI-Session)

export AWS_ACCESS_KEY_ID=$(echo $role | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $role | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $role | jq -r .Credentials.SessionToken)

eksctl get iamidentitymapping --cluster eks-eda --region=$AWS_REGION
eksctl create iamidentitymapping --cluster  eks-eda --region=$AWS_REGION --arn arn:aws:iam::$ACCOUNT_ID:role/role-cloud9-cdk \
                                 --group system:masters --username admin
eksctl create iamidentitymapping --cluster eks-eda --region=$AWS_REGION \
    --arn arn:aws:iam::$ACCOUNT_ID:user/silverte --group system:masters --username silverte \
    --no-duplicate-arns

eksctl create iamidentitymapping --cluster eks-eda --region=$AWS_REGION \
    --arn arn:aws:iam::$ACCOUNT_ID:user/whchoi823 --group system:masters --username whchoi823 \
    --no-duplicate-arns

eksctl create iamidentitymapping --cluster eks-eda --region=$AWS_REGION \
    --arn arn:aws:iam::$ACCOUNT_ID:user/scottkim --group system:masters --username scottkim \
    --no-duplicate-arns

eksctl create iamidentitymapping --cluster eks-eda --region=$AWS_REGION \
    --arn arn:aws:iam::$ACCOUNT_ID:user/nextkong --group system:masters --username nextkong \
    --no-duplicate-arns

eksctl create iamidentitymapping --cluster eks-eda --region=$AWS_REGION \
    --arn arn:aws:iam::$ACCOUNT_ID:user/euroup --group system:masters --username euroup \
    --no-duplicate-arns

                          


