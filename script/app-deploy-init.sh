#!/bin/bash

export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export BASE_DIR=~/environment/src
export STACKS=$(aws cloudformation describe-stacks)

#kafka 라이브러리 다운로드
mkdir ~/environment/src
wget https://archive.apache.org/dist/kafka/2.6.2/kafka_2.12-2.6.2.tgz -P $BASE_DIR
#extract archive file
tar -xzf ~/environment/src/kafka_2.12-2.6.2.tgz -C $BASE_DIR

# repository 복제
git clone https://github.com/silverte/amazon-msk-spring-boot-eda-customer.git $BASE_DIR/amazon-msk-spring-boot-eda-customer
git clone https://github.com/silverte/amazon-msk-spring-boot-eda-order.git $BASE_DIR/amazon-msk-spring-boot-eda-order

# msk topic 생성
export ZOOKEEPER=$(echo $STACKS | jq -r '.Stacks[]?.Outputs[]? | select(.ExportName=="zookeeper-connection-string") | .OutputValue')
export BOOTSTRAP_SERVER=$(echo $STACKS | jq -r '.Stacks[]?.Outputs[]? | select(.ExportName=="bootstrap-brokers") | .OutputValue')
echo $ZOOKEEPER
echo $BOOTSTRAP_SERVER

$BASE_DIR/kafka_2.12-2.6.2/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER --replication-factor 3 --partitions 1 --topic customerTopic
$BASE_DIR/kafka_2.12-2.6.2/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER --replication-factor 3 --partitions 1 --topic orderTopic

# topic 확인
$BASE_DIR/kafka_2.12-2.6.2/bin/kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --list

# customer app build and ECR push
STACKS=$(aws cloudformation describe-stacks)
export RDS_ENDPOINT_CUSTOMER=$(echo $STACKS | jq -r '.Stacks[]?.Outputs[]? | select(.ExportName=="rds-endpoint-customer") | .OutputValue')
cd $BASE_DIR/amazon-msk-spring-boot-eda-customer/customer-service
./gradlew build
docker build -t customer .
#java -jar ./build/libs/customer-service-0.0.1-SNAPSHOT.jar
export= CUSTOMER_REPOSITORY_URI=$(aws ecr create-repository --repository-name customer-service --region ap-northeast-2 | jq -r '.repository.repositoryUri')
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $CUSTOMER_REPOSITORY_URI
docker tag customer:latest $CUSTOMER_REPOSITORY_URI
docker push $CUSTOMER_REPOSITORY_URI

# order app build and ECR push
export RDS_ENDPOINT_ORDER=$(echo $STACKS | jq -r '.Stacks[]?.Outputs[]? | select(.ExportName=="rds-endpoint-order") | .OutputValue')
cd $BASE_DIR/amazon-msk-spring-boot-eda-order/order-service
./gradlew build
docker build -t order .

export= ORDER_REPOSITORY_URI=$(aws ecr create-repository --repository-name order-service --region ap-northeast-2 | jq -r '.repository.repositoryUri')
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ORDER_REPOSITORY_URI
docker tag order:latest $ORDER_REPOSITORY_URI
docker push $ORDER_REPOSITORY_URI

# update deployment manifest values
cd $BASE_DIR/amazon-msk-spring-boot-eda-customer/customer-service/k8s
sed -i  -e s/\$image/$(echo -n $CUSTOMER_REPOSITORY_URI | cut -d '/' -f 1)\\/customer-service/g \
        -e s/\$bootstrap-server/$(echo -n $BOOTSTRAP_SERVER)/g                                  \
        -e s/\$rds-endpoint-customer/$(echo -n $RDS_ENDPOINT_CUSTOMER)/g                        \
        ./customer-deployment.yaml

cd $BASE_DIR/amazon-msk-spring-boot-eda-order/order-service/k8s
sed -i  -e s/\$image/$(echo -n $ORDER_REPOSITORY_URI | cut -d '/' -f 1)\\/order-service/g \
        -e s/\$bootstrap-server/$(echo -n $BOOTSTRAP_SERVER)/g                            \
        -e s/\$rds-endpoint-order/$(echo -n $RDS_ENDPOINT_ORDER)/g                        \
        ./order-deployment.yaml

# create deployment, servic and ingress
cp $BASE_DIR/amazon-msk-spring-boot-eda-customer/customer-service/k8s/* ~/environment/techguru-msa/script/k8s
cp $BASE_DIR/amazon-msk-spring-boot-eda-order/order-service/k8s/* ~/environment/techguru-msa/script/k8s

cd ~/environment/techguru-msa/script/k8s
kubectl create -f *-deployment.yaml
kubectl create -f *-service.yaml
kubectl create -f ingress.yaml