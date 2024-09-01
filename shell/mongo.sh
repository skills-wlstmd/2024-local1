# Mongo
cat <<EOF | sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/aarch64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

# MongoDB 설치
sudo yum install -y mongodb-org

# 서비스 시작
sudo systemctl start mongod

# 서비스 활성화 (부팅 시 자동 시작)
sudo systemctl enable mongod

# 서비스 상태 확인
sudo systemctl status mongod


