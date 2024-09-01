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

# IAM OIDC 제공자 연결
eksctl utils associate-iam-oidc-provider --region=ap-northeast-2 --cluster=skills-eks-cluster --approve

# IAM 정책 생성
aws iam create-policy --policy-name SecretsManagerPolicy --policy-document file://secret-policy.json

# IAM 서비스 계정 생성
eksctl create iamserviceaccount \
    --name external-secrets-cert-controller \
    --region=ap-northeast-2 \
    --cluster skills-eks-cluster \
    --namespace=skills \
    --attach-policy-arn arn:aws:iam::362708816803:policy/SecretsManagerPolicy \
    --override-existing-serviceaccounts \
    --approve

# Helm 저장소 추가 및 업데이트
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# 서비스 계정에 주석 및 라벨 추가
kubectl annotate serviceaccount external-secrets-cert-controller \
  meta.helm.sh/release-name=external-secrets \
  meta.helm.sh/release-namespace=skills \
  -n skills \
  --overwrite

kubectl label serviceaccount external-secrets-cert-controller \
  app.kubernetes.io/managed-by=Helm \
  -n skills \
  --overwrite

# values.yaml 파일 생성
cat > values.yaml <<EOF
installCRDs: true
nodeSelector:
  eks.amazonaws.com/nodegroup: skills-eks-addon-nodegroup
webhook:
  nodeSelector:
    eks.amazonaws.com/nodegroup: skills-eks-addon-nodegroup
certController:
  nodeSelector:
    eks.amazonaws.com/nodegroup: skills-eks-addon-nodegroup
EOF

# External Secrets 설치
helm install external-secrets \
  external-secrets/external-secrets \
  -n kube-system \
  -f values.yaml \
  --set serviceAccount.create=false

kubectl apply -f secretstore.yaml
kubectl apply -f external-secret-operator.yaml

# skills-user 리소스 배포
kubectl apply -k skills-user/
kubectl delete -k skills-user/

# skills-token 리소스 배포
kubectl apply -k skills-token/
kubectl delete -k skills-token/

# Pod 상태 확인
kubectl get pod -n skills

# 모든 Pod 삭제 (필요시)
kubectl delete pod -n skills --all

aws secretsmanager get-secret-value --secret-id aws-secret --query SecretString --output text
aws secretsmanager get-secret-value --secret-id redis/credentials --query SecretString --output text