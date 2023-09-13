#!/bin/bash
if [ -n "${1}" ]; then
  echo "profile: ${1}"
  export AWS_PROFILE=${1}
fi

if [ "$AWS_PROFILE" = "" ]; then
  echo "No AWS_PROFILE set"
  exit 1
fi

echo "Using profile $AWS_PROFILE"

cdk context --clear

# cdk bootstrap
export STAGE="Vpc"
cdk bootstrap

# deploy stacks
export STAGE="Vpc"
cdk deploy vpc-techguru --require-approval never
export STAGE="Stacks"
cdk deploy "rds-*" "eks-*" "msk-*" --require-approval never --concurrency 10