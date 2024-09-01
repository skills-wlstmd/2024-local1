# eksctl, kubectl, awscli v2 install on arm64

### eksctl

https://learn.arm.com/install-guides/eksctl/

```bash
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_arm64.tar.gz"
tar -xzf eksctl_Linux_arm64.tar.gz -C /tmp && rm eksctl_Linux_arm64.tar.gz
sudo mv /tmp/eksctl /usr/local/bin
# check
eksctl version
```

### kubectl

https://kubernetes.io/ko/docs/tasks/tools/install-kubectl-linux/

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl.sha256"
echo "$(cat kubectl.sha256) kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
# check
kubectl version --client
```

### aws cli v2

https://aws.amazon.com/ko/blogs/developer/aws-cli-v2-now-available-for-linux-arm/

```bash
uname -r
curl -O 'https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip'
unzip awscli-exe-linux-aarch64.zip
sudo ./aws/install
# check
aws --version
```
