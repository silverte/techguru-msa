#!/bin/bash

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

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# storage class 생성
mkdir -p ~/environment/ebs_csi/
cat <<EOF> ~/environment/ebs_csi/ebs_obs_sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-obs-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
EOF
kubectl apply -f ~/environment/ebs_csi/ebs_obs_sc.yaml

# prometheus 설치
kubectl create namespace prometheus
helm upgrade -i prometheus prometheus-community/prometheus \
    --namespace prometheus \
    --set alertmanager.persistentVolume.storageClass="ebs-obs-sc",server.persistentVolume.storageClass="ebs-obs-sc"
    
#kubectl port-forward -n prometheus deploy/prometheus-server 8081:9090 &
    
# The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
# prometheus-server.prometheus.svc.cluster.local

# grafana 설치
mkdir ~/environment/grafana
kubectl create namespace grafana
cat <<EoF > ~/environment/grafana/grafana.yaml
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server.prometheus.svc.cluster.local
      access: proxy
      isDefault: true
EoF

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install grafana grafana/grafana \
    --namespace grafana \
    --set persistence.storageClassName="ebs-obs-sc" \
    --set persistence.enabled=true \
    --set adminPassword='q1w2e3R$' \
    --values ${HOME}/environment/grafana/grafana.yaml \
    --set service.type=LoadBalancer \
    --set service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"="internet-facing"

kubectl -n grafana get svc grafana  | tail -n 1 | awk '{ print "grafana URL = http://"$4 }'