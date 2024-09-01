REGION_CORD="ap-northeast-2"
CLUSTER_NAME="skills-eks-cluster"

cat >secret-policy.json <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"secretsmanager:GetResourcePolicy",
				"secretsmanager:GetSecretValue",
				"secretsmanager:DescribeSecret",
				"secretsmanager:ListSecretVersionIds"
			],
			"Resource": ["*"]
		},
      {
        "Effect": "Allow",
        "Action": ["kms:Decrypt"],
        "Resource": ["*"]
      }
    ]
}
EOF

POLICY_ARN=$(aws --region "$REGION_CORD" --query Policy.Arn --output text iam create-policy --policy-name secretsmanager-policy --policy-document file://secret-policy.json)

eksctl create iamserviceaccount \
    --name external-secrets-cert-controller \
    --region="$REGION_CORD" \
    --cluster "$CLUSTER_NAME" \
    --namespace=skills \
    --attach-policy-arn "$POLICY_ARN" \
    --override-existing-serviceaccounts \
    --approve

helm repo add external-secrets https://charts.external-secrets.io

kubectl annotate serviceaccount external-secrets-cert-controller \
  meta.helm.sh/release-name=external-secrets \
  meta.helm.sh/release-namespace=skills \
  -n skills \
  --overwrite

kubectl label serviceaccount external-secrets-cert-controller \
  app.kubernetes.io/managed-by=Helm \
  -n skills \
  --overwrite

cat > values.yaml <<EOF
{
  "installCRDs": true,
  "nodeSelector": {
    "eks.amazonaws.com/nodegroup": "skills-eks-addon-nodegroup"
  },
  "webhook": {
    "nodeSelector": {
      "eks.amazonaws.com/nodegroup": "skills-eks-addon-nodegroup"
    }
  },
  "certController": {
    "nodeSelector": {
      "eks.amazonaws.com/nodegroup": "skills-eks-addon-nodegroup"
    }
  }
}
EOF

helm install external-secrets \
   external-secrets/external-secrets \
   -n kube-system \
   -f values.yaml \
   --set serviceAccount.create=false

cat <<\EOF> secretstore.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets
  namespace: skills
spec:
  provider:
    aws:
      service: SecretsManager
      region: ap-northeast-2
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-cert-controller
EOF

kubectl apply -f secretstore.yaml

cat <<\EOF> token.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: token
  namespace: skills
spec:
  refreshInterval: 30s
  secretStoreRef:
    name: aws-secrets
    kind: SecretStore
  target:
    name: token
    creationPolicy: Owner
  data:
    - secretKey: REDIS_HOST 
      remoteRef:
        key: redis/credentials
        property: host
    - secretKey: REDIS_PORT
      remoteRef:
        key: redis/credentials
        property: port
EOF

kubectl apply -f token.yaml

cat <<\EOF> user.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: user
  namespace: skills
spec:
  refreshInterval: 30s
  secretStoreRef:
    name: aws-secrets
    kind: SecretStore
  target:
    name: user
    creationPolicy: Owner
  data:
    - secretKey: MONGODB_USERNAME 
      remoteRef:
        key: mongodb/credentials
        property: username
    - secretKey: MONGODB_PASSWORD
      remoteRef:
        key: mongodb/credentials
        property: password
    - secretKey: MONGODB_HOST
      remoteRef:
        key: mongodb/credentials
        property: host
    - secretKey: MONGODB_PORT
      remoteRef:
        key: mongodb/credentials
        property: port
    - secretKey: MYSQL_DBNAME
      remoteRef:
        key: mongodb/credentials
        property: region
    - secretKey: AWS_REGION
      remoteRef:
        key: mongodb/credentials
        property: dbname
    - secretKey: AWS_SECRET_NAME
      remoteRef:
        key: mongodb/credentials
        property: secret_name
    - secretKey: TOKEN_ENDPOINT
      remoteRef:
        key: mongodb/credentials
        property: token_endpoint
EOF

kubectl apply -f user.yaml