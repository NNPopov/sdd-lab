#!/bin/bash
# ============================================================
# deploy.sh — Build, Push, Deploy to EKS
#
# Использование:
#   ./scripts/deploy.sh both      # backend + frontend
#   ./scripts/deploy.sh api       # только backend
#   ./scripts/deploy.sh flutter   # только frontend
#   ./scripts/deploy.sh both --skip-build
# ============================================================

set -e

SERVICE=${1:-both}
SKIP_BUILD=${2:-""}

# --- Конфигурация ---
ACCOUNT_ID="017091936354"
REGION="us-east-1"
CLUSTER="fastapi-demo-cluster"
NAMESPACE="fastapi-demo"
REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
BACKEND_IMG="$REGISTRY/fastapi-demo/backend:latest"
FRONTEND_IMG="$REGISTRY/fastapi-demo/frontend:latest"

# Цвета
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${CYAN}==> $1${NC}"; }
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }

# Путь к корню монорепо
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

# --- 1. Логин в ECR ---
log "Logging in to ECR..."
aws ecr get-login-password --region $REGION | \
    docker login --username AWS --password-stdin $REGISTRY
ok "ECR login successful"

# --- 2. Build ---
if [ "$SKIP_BUILD" != "--skip-build" ]; then
    if [ "$SERVICE" = "api" ] || [ "$SERVICE" = "both" ]; then
        log "Building API image..."
        docker build -f docker/Dockerfile.api -t $BACKEND_IMG api/
        ok "API image built"
    fi

    if [ "$SERVICE" = "flutter" ] || [ "$SERVICE" = "both" ]; then
        log "Building Flutter image..."
        docker build -f docker/Dockerfile.flutter -t $FRONTEND_IMG .
        ok "Flutter image built"
    fi
fi

# --- 3. Push ---
if [ "$SERVICE" = "api" ] || [ "$SERVICE" = "both" ]; then
    log "Pushing API image..."
    docker push $BACKEND_IMG
    ok "API image pushed"
fi

if [ "$SERVICE" = "flutter" ] || [ "$SERVICE" = "both" ]; then
    log "Pushing Flutter image..."
    docker push $FRONTEND_IMG
    ok "Flutter image pushed"
fi

# --- 4. kubectl apply ---
log "Applying K8s manifests..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER
ok "K8s manifests applied"

# --- 5. Rollout restart ---
if [ "$SERVICE" = "api" ] || [ "$SERVICE" = "both" ]; then
    log "Restarting API deployment..."
    kubectl rollout restart deployment/fastapi-backend -n $NAMESPACE
    kubectl rollout status deployment/fastapi-backend -n $NAMESPACE --timeout=300s
    ok "API deployment updated"
fi

if [ "$SERVICE" = "flutter" ] || [ "$SERVICE" = "both" ]; then
    log "Restarting Flutter deployment..."
    kubectl rollout restart deployment/flutter-frontend -n $NAMESPACE
    kubectl rollout status deployment/flutter-frontend -n $NAMESPACE --timeout=300s
    ok "Flutter deployment updated"
fi

# --- 6. Статус ---
echo ""
log "Current pods:"
kubectl get pods -n $NAMESPACE

echo ""
log "Ingress URL:"
kubectl get ingress -n $NAMESPACE
