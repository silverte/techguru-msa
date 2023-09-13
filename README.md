# Stacks for TechGuru MSA Champions

## node.js 설치

https://nodejs.org/ko LTS version

## cdk CLI 설치

npm install -g aws-cdk

## Stack 배포(VPC, MSK, EKS, RDS)

sh setup.sh

## 배포환경 구성

- cloud9 생성: VPC public subnet 지정
- IAM role 생성: role-cloud9-cdk 이름으로 생성, managed Admin policy 연결
- cloud9 instance role을 role-cloud9-cdk로 변경, managed temp credential off
- cloudformation에서 eks-eda stack의 output에서 eksedaConfigCommand value 복사 후 실행
- eks-eda-eksedaAccessRoleXXXXXXX role에 managed Admin policy 연결

## App 배포

- cd script
- sh cloud9-resize.sh 50
- sh cloud9-setup.sh (java-11-amazon-corretto 버전으로 선택)
- sg-XXXXX-eks-cluster-sg-eks-eda-XXXX inbound rule 추가: 443 cloud9 private IP or any
- kubectl get no 확인
- sh assume-role.sh
- sh app-deploy-init.sh
- alb-eda-ingress security group ingress rule 추가 80 any
- alb DNS + /customer-order/customer-service + swagger/ 페이지 확인
