#!/bin/bash

# =============================================================================
# SEAL SECRET - Universal script for encrypting secrets with kubeseal
# =============================================================================
# Usage: ./seal-secret.sh SECRET_NAME KEY VALUE NAMESPACE
# Example: ./seal-secret.sh database-credentials password "mySecretPassword123" production
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_FILE="${SCRIPT_DIR}/sealed-secrets.pub.pem"

# Arguments
SECRET_NAME=${1:-}
KEY=${2:-}
VALUE=${3:-}
NAMESPACE=${4:-}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} ${1}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} ${1}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} ${1}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} ${1}"
}

# Check arguments
if [ "${#}" -ne 4 ]; then
    log_error "Invalid number of arguments!"
    echo ""
    echo "Usage: ${0} SECRET_NAME KEY VALUE NAMESPACE"
    echo ""
    echo "Examples:"
    echo "  ${0} database-credentials password \"mySecretPassword123\" production"
    echo "  ${0} api-keys token \"abc123xyz789\" development"
    echo "  ${0} tls-cert tls.crt \"\$(cat cert.pem)\" default"
    echo ""
    exit 1
fi

# Check if kubeseal is installed
if ! command -v kubeseal &> /dev/null; then
    log_error "kubeseal is not installed!"
    echo ""
    echo "Install kubeseal:"
    echo "  KUBESEAL_VERSION=\"0.29.0\""
    echo "  curl -OL \"https://github.com/bitnami-labs/sealed-secrets/releases/download/v\${KUBESEAL_VERSION}/kubeseal-\${KUBESEAL_VERSION}-linux-amd64.tar.gz\""
    echo "  tar -xzf kubeseal-\${KUBESEAL_VERSION}-linux-amd64.tar.gz"
    echo "  sudo install -m 755 kubeseal /usr/local/bin/kubeseal"
    echo ""
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is not installed!"
    exit 1
fi

# Check if certificate exists
if [[ ! -f "${CERT_FILE}" ]]; then
    log_warning "Certificate file not found: ${CERT_FILE}"
    log_info "Attempting to extract certificate from main.key..."
    
    if [[ -f "${SCRIPT_DIR}/main.key" ]]; then
        # Extract certificate from main.key
        kubectl get -f "${SCRIPT_DIR}/main.key" -o jsonpath='{.items[0].data.tls\.crt}' | base64 -d > "${CERT_FILE}" 2>/dev/null || {
            log_error "Failed to extract certificate from main.key"
            log_info "Trying to get certificate from running controller..."
            kubectl get secret -n kube-system sealed-secrets-key -o jsonpath='{.data.tls\.crt}' | base64 -d > "${CERT_FILE}" 2>/dev/null || {
                log_error "Failed to get certificate from controller. Make sure Sealed Secrets Controller is running."
                exit 1
            }
        }
        log_success "Certificate extracted to ${CERT_FILE}"
    else
        log_error "main.key file not found and cannot extract certificate"
        exit 1
    fi
fi

# Temporary files
TEMP_SECRET="${SCRIPT_DIR}/temp-secret-$$.yaml"
OUTPUT_FILE="${SCRIPT_DIR}/${SECRET_NAME}.sealed.yaml"

# Cleanup function
cleanup() {
    rm -f "${TEMP_SECRET}"
}
trap cleanup EXIT

log_info "Creating secret: ${SECRET_NAME}"
log_info "Key: ${KEY}"
log_info "Namespace: ${NAMESPACE}"

# Generate secret file in YAML format
echo "${VALUE}" | kubectl create secret generic "${SECRET_NAME}" \
    --dry-run=client \
    --from-file="${KEY}"=/dev/stdin \
    -o yaml > "${TEMP_SECRET}"

if [[ ! -f "${TEMP_SECRET}" ]]; then
    log_error "Failed to create temporary secret file"
    exit 1
fi

log_success "Temporary secret file created"

# Encrypt secret using kubeseal for the corresponding namespace
log_info "Encrypting secret for namespace: ${NAMESPACE}"

if kubeseal --namespace "${NAMESPACE}" --format=yaml --cert="${CERT_FILE}" < "${TEMP_SECRET}" > "${OUTPUT_FILE}"; then
    log_success "Secret encrypted successfully!"
    log_success "Output file: ${OUTPUT_FILE}"
    echo ""
    log_info "You can now apply this secret to your cluster:"
    echo "  kubectl apply -f ${OUTPUT_FILE}"
    echo ""
    log_info "Or add the contents to your values.yaml, dev.yaml or prod.yaml files."
    echo ""
    
    # Show first few lines of the output
    log_info "Preview of encrypted secret:"
    echo "---"
    head -20 "${OUTPUT_FILE}"
    if [[ $(wc -l < "${OUTPUT_FILE}") -gt 20 ]]; then
        echo "... (truncated)"
    fi
    echo "---"
    
else
    log_error "Failed to encrypt secret"
    exit 1
fi

log_success "Operation completed successfully!" 