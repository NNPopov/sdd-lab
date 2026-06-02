#!/usr/bin/env bash
# ============================================================
# deploy-serverless.sh - Build, Push (ECR), Deploy (ECS + S3/CloudFront)
#
# Mirrors deploy.sh but targets the serverless stack.
#
# Usage:
#   ./scripts/deploy-serverless.sh both
#   ./scripts/deploy-serverless.sh api
#   ./scripts/deploy-serverless.sh flutter
#   DEPLOY_ONLY=1 ./scripts/deploy-serverless.sh api
#   RUN_MIGRATIONS=1 ./scripts/deploy-serverless.sh api
# ============================================================
set -euo pipefail

SERVICE="${1:-both}"
DEPLOY_ONLY="${DEPLOY_ONLY:-0}"
SKIP_BUILD="${SKIP_BUILD:-0}"
RUN_MIGRATIONS="${RUN_MIGRATIONS:-0}"

ACCOUNT_ID="017091936354"
REGION="us-east-1"
PROJECT="fastapi-demo-sl"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
BACKEND_REPO="${PROJECT}/backend"
BACKEND_IMG="${REGISTRY}/${BACKEND_REPO}:latest"
CLUSTER="${PROJECT}-cluster"
SERVICE_NAME="${PROJECT}-api"
TASK_FAMILY="${PROJECT}-api"
CONTAINER="api"
BUCKET="${PROJECT}-web-${ACCOUNT_ID}"
COMMENT="${PROJECT} — Flutter web + /api proxy"

log()  { echo -e "\033[36m==> $1\033[0m"; }
ok()   { echo -e "\033[32m[OK] $1\033[0m"; }
err()  { echo -e "\033[31m[ERR] $1\033[0m"; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# ---------- Build + push API ----------
if [ "$DEPLOY_ONLY" != "1" ] && { [ "$SERVICE" = "api" ] || [ "$SERVICE" = "both" ]; }; then
  log "Logging in to ECR..."
  aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"
  ok "ECR login successful"

  if [ "$SKIP_BUILD" != "1" ]; then
    log "Building API image..."
    docker build -f docker/Dockerfile.api -t "$BACKEND_IMG" api/
    ok "API image built"
  fi

  log "Pushing API image..."
  docker push "$BACKEND_IMG"
  ok "API image pushed"
fi

# ---------- Migrations ----------
if [ "$RUN_MIGRATIONS" = "1" ] && { [ "$SERVICE" = "api" ] || [ "$SERVICE" = "both" ]; }; then
  log "Running Alembic migrations as an ECS task..."
  NETWORK=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE_NAME" \
    --query 'services[0].networkConfiguration' --output json)
  TASK_ARN=$(aws ecs run-task --cluster "$CLUSTER" --task-definition "$TASK_FAMILY" \
    --launch-type FARGATE --network-configuration "$NETWORK" \
    --overrides '{"containerOverrides":[{"name":"'"$CONTAINER"'","command":["alembic","upgrade","head"]}]}' \
    --query 'tasks[0].taskArn' --output text)
  log "Migration task: $TASK_ARN"
  aws ecs wait tasks-stopped --cluster "$CLUSTER" --tasks "$TASK_ARN"
  EXIT_CODE=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$TASK_ARN" \
    --query "tasks[0].containers[?name=='$CONTAINER'].exitCode | [0]" --output text)
  [ "$EXIT_CODE" = "0" ] || err "Migrations failed (exit $EXIT_CODE)"
  ok "Migrations completed"
fi

# ---------- Deploy API -> ECS ----------
if [ "$SERVICE" = "api" ] || [ "$SERVICE" = "both" ]; then
  log "Registering new task definition revision..."
  IMAGE="${REGISTRY}/${BACKEND_REPO}:latest"
  aws ecs describe-task-definition --task-definition "$TASK_FAMILY" --query 'taskDefinition' --output json \
    | jq --arg IMG "$IMAGE" --arg NAME "$CONTAINER" '
        (.containerDefinitions[] | select(.name==$NAME) | .image) = $IMG
        | del(.taskDefinitionArn, .revision, .status, .requiresAttributes,
              .compatibilities, .registeredAt, .registeredBy)' > new-task-def.json
  aws ecs register-task-definition --cli-input-json file://new-task-def.json >/dev/null
  rm -f new-task-def.json

  log "Forcing new ECS deployment..."
  aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE_NAME" \
    --task-definition "$TASK_FAMILY" --force-new-deployment >/dev/null
  aws ecs wait services-stable --cluster "$CLUSTER" --services "$SERVICE_NAME"
  ok "API deployment stable"
fi

# ---------- Deploy Flutter -> S3 + CloudFront ----------
if [ "$SERVICE" = "flutter" ] || [ "$SERVICE" = "both" ]; then
  log "Building Flutter web..."
  ( cd flutter && flutter pub get && flutter build web --release --dart-define-from-file=config/prod-web.json )

  log "Syncing to S3..."
  aws s3 sync flutter/build/web "s3://$BUCKET" --delete

  log "Invalidating CloudFront..."
  DIST_ID=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Comment=='$COMMENT'].Id | [0]" --output text)
  aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths "/*" >/dev/null
  ok "Flutter deployed and CloudFront invalidated"
fi

echo ""
log "Done. App URL:"
aws cloudfront list-distributions \
  --query "DistributionList.Items[?Comment=='$COMMENT'].DomainName | [0]" --output text
