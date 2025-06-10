# Sealed Secrets - Secret Manager

## Requirements

### Local requirements
- `kubectl` - Kubernetes client
- `kubeseal` - tool for encrypting secrets

### Cluster requirements
- Sealed Secrets Controller installed in `kube-system` namespace
- Private and public keys installed in the controller

## Install kubeseal (locally)

```bash
# Download the latest kubeseal version
KUBESEAL_VERSION="0.29.0"
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
tar -xzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

## Key preparation

### Step 1: Get key from existing cluster
```bash
# Download private key from running controller
kubectl get secret -n kube-system sealed-secrets-key -o yaml > main.key

# Extract public certificate from main.key
grep "tls.crt:" main.key | cut -d' ' -f6 | base64 -d > sealed-secrets.pub.pem
```

## Usage

### Encrypting secrets
```bash
# Basic usage
./seal-secret.sh SECRET_NAME KEY VALUE NAMESPACE

# Examples
./seal-secret.sh database-credentials password "mySecretPassword123" production
./seal-secret.sh api-keys token "abc123xyz789" development
```

### Result
The script will create a `SECRET_NAME.sealed.yaml` file ready to use in Kubernetes manifest or the value can be used in values.yaml file in the env section of a given project.

## Troubleshooting

### Error: "no key could decrypt secret"
- Make sure you're using the same key as on the cluster
- Check if controller is running: `kubectl get pods -n kube-system | grep sealed`

### Error: "kubeseal: command not found"
- Install kubeseal according to the instructions above

### Error during controller installation
- Check if keys were properly uploaded: `kubectl get secret -n kube-system sealed-secrets-key`
