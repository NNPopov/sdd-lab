#!/usr/bin/env bash
# ============================================================
# destroy-serverless.sh - Tear down the serverless stack.
#
# Single clean `terraform destroy` — the ALB, S3 bucket and ECR are
# all owned by Terraform (force_delete / force_destroy), so there are
# no orphaned resources and no manual pre-steps (unlike the EKS stack).
#
# Usage: ./scripts/destroy-serverless.sh
# ============================================================
set -euo pipefail

log()  { echo -e "\033[36m==> $1\033[0m"; }
ok()   { echo -e "\033[32m[OK] $1\033[0m"; }
warn() { echo -e "\033[33m[WARN] $1\033[0m"; }

echo -e "\033[31m[!] This will destroy the SERVERLESS stack (ECS/RDS/Redis/ALB/S3/CloudFront)!\033[0m"
read -r -p "Type 'yes' to confirm: " confirm
[ "$confirm" = "yes" ] || { echo "Cancelled."; exit 0; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../terraform/serverless"

log "Running terraform destroy..."
if terraform destroy -auto-approve; then
  ok "Serverless stack destroyed!"
else
  warn "terraform destroy had errors - check manually"
fi
