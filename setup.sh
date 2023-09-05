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

cdk bootstrap

export STAGE="Vpc"
cdk deploy Vpc --require-approval never

export STAGE="Stacks"
cdk deploy "Rds*" "Eks" "Msk" --require-approval never --concurrency 10 
