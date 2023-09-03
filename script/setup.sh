#!/bin/bash

cdk deploy Vpc --require-approval never --profile msa
cdk deploy "Rds*" "Eks" "Msk" --profile msa --require-approval never --concurrency 10 
