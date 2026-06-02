#!/bin/bash
# ============================================================
# destroy.sh — Безопасное удаление всего стека
#
# Использование:
#   ./scripts/destroy.sh
#
# Порядок удаления:
#   1. K8s namespace (LBC удалит ALB + SG автоматически)
#   2. Ждём пока AWS почистит ресурсы
#   3. terraform destroy
# ============================================================

set -e

REGION="us-east-1"
CLUSTER="fastapi-demo-cluster"
NAMESPACE="fastapi-demo"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${CYAN}==> $1${NC}"; }
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Подтверждение ---
echo -e "${RED}⚠️  This will destroy ALL resources!${NC}"
read -p "Type 'yes' to confirm: " confirm
if [ "$confirm" != "yes" ]; then echo "Cancelled."; exit 0; fi

# --- 1. Обновить kubeconfig ---
log "Updating kubeconfig..."
if aws eks update-kubeconfig --region $REGION --name $CLUSTER 2>/dev/null; then

    # --- 2. Удалить namespace ---
    log "Deleting K8s namespace '$NAMESPACE'..."
    kubectl delete namespace $NAMESPACE --ignore-not-found=true
    ok "Namespace deleted — waiting for ALB cleanup..."

    # --- 3. Ждём удаления ALB ---
    log "Waiting for AWS Load Balancer Controller cleanup..."
    for i in $(seq 9 -1 1); do
        sleep 10
        echo "  ${i}0 seconds remaining..."
        albs=$(aws elbv2 describe-load-balancers --region $REGION \
            --query "LoadBalancers[?contains(LoadBalancerName, 'fastapid')].LoadBalancerName" \
            --output text 2>/dev/null || true)
        if [ -z "$albs" ]; then
            ok "ALB deleted!"
            break
        fi
    done

    # --- 4. Принудительное удаление ALB если остался ---
    albs=$(aws elbv2 describe-load-balancers --region $REGION \
        --query "LoadBalancers[?contains(LoadBalancerName, 'fastapid')].LoadBalancerArn" \
        --output text 2>/dev/null || true)

    if [ -n "$albs" ]; then
        warn "ALB still exists — deleting manually..."
        for arn in $albs; do
            aws elbv2 delete-load-balancer --load-balancer-arn "$arn" --region $REGION
            sleep 15
        done
    fi

    # --- 5. Удалить orphan Security Groups ---
    log "Cleaning up orphan Security Groups..."
    # Only delete SGs created by LBC (name starts with k8s-)
    # Skip eks-cluster-sg-* which is managed by Terraform
    sgs=$(aws ec2 describe-security-groups --region $REGION \
        --filters "Name=tag:kubernetes.io/cluster/$CLUSTER,Values=owned" \
                  "Name=group-name,Values=k8s-*" \
        --query "SecurityGroups[].GroupId" \
        --output text 2>/dev/null || true)

    for sg in $sgs; do
        if [ -n "$sg" ] && [ "$sg" != "None" ]; then
            echo "  Deleting SG: $sg"
            aws ec2 delete-security-group --group-id "$sg" --region $REGION 2>/dev/null || true
        fi
    done

else
    warn "Could not connect to cluster — may already be deleted"
fi

# --- 6. Terraform destroy ---
log "Running terraform destroy..."
cd "$ROOT_DIR/terraform/eks"
terraform destroy -auto-approve
ok "All resources destroyed!"