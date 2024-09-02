# 명령어 방식
# EKS 클러스터 생성
eksctl create cluster --name skills-eks-cluster --version latest --region ap-northeast-2 --vpc-private-subnets subnet-0665279ae6e13fad8,subnet-04e67a258cb6bda51 --without-nodegroup

# Addon Nodegroup 생성 (프라이빗 서브넷 지정)
eksctl create nodegroup \
  --cluster skills-eks-cluster \
  --name skills-eks-addon-nodegroup \
  --node-type t4g.large \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 4 \
  --node-labels "Name=skills-eks-addon-node" \
  --subnet-ids subnet-0665279ae6e13fad8,subnet-04e67a258cb6bda51 \
  --node-private-networking

# App Nodegroup 생성 (프라이빗 서브넷 지정)
eksctl create nodegroup \
  --cluster skills-eks-cluster \
  --name skills-eks-app-nodegroup \
  --node-type m6g.large --nodes 2 \
  --nodes-min 2 --nodes-max 4 \
  --node-labels "Name=skills-eks-app-node" \
  --subnet-ids subnet-0665279ae6e13fad8,subnet-04e67a258cb6bda51 \
  --node-private-networking

# Fargate Profile 생성
eksctl create fargateprofile \
  --cluster skills-eks-cluster \
  --name skills-eks-app-profile \
  --namespace skills \
  --labels app=token

# 파일 형식
eksctl create cluster -f cluster.yaml

# KMS Key 생성
aws kms create-key --description "KMS key for EKS secrets encryption"

# Namespace 생성
kubectl create namespace skills

# Pod 상태 확인
kubectl get pod -n skills

# 모든 Pod 삭제 (필요시)
kubectl delete pod -n skills --all