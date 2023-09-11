#!/bin/bash

# cdk 설치
rm $(which cdk)
npm install -g aws-cdk
cdk --version
npm install -g npm
npm i aws-cdk-lib

# yarn 설치
corepack enable
corepack prepare yarn --activate

# kubectl 설치
sudo curl --silent --location -o /usr/local/bin/kubectl \
    https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.7/2022-06-29/bin/linux/amd64/kubectl
sudo chmod +x /usr/local/bin/kubectl
kubectl version
alias k=kubectl
kubectl completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

# eksctl 설치
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin

# helm 설치
curl -L https://git.io/get_helm.sh | bash -s -- --version v3.8.2
helm version --short
helm completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion
source <(helm completion bash)
helm repo add stable https://charts.helm.sh/stable
helm repo update
#helm search repo stable

# aws cli 설치
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip 
sudo ./aws/install
aws --version
sudo yum -y install jq gettext bash-completion moreutils
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get default.region

# disk size 증설
bash ./cloud9-stetup.sh 50

# maven 설치 및 설정
sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
sudo sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo
sudo yum install -y apache-maven
sudo yum install -y java-11-amazon-corretto.x86_64

# java 버전 변경
# sudo alternatives --config java
# sudo alternatives --config javac