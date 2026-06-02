# ============================================================
# deploy-serverless.ps1 - Build, Push (ECR), Deploy (ECS + S3/CloudFront)
#
# Mirrors deploy.ps1 but targets the serverless stack:
#   - API   -> ECR -> ECS Fargate (new task def revision + force deploy)
#   - Flutter -> S3 sync + CloudFront invalidation
#
# Usage:
#   .\scripts\deploy-serverless.ps1 -Service both
#   .\scripts\deploy-serverless.ps1 -Service api
#   .\scripts\deploy-serverless.ps1 -Service flutter
#   .\scripts\deploy-serverless.ps1 -Service api -DeployOnly   # no docker build
#   .\scripts\deploy-serverless.ps1 -Service api -RunMigrations
# ============================================================

param(
    [ValidateSet("api", "flutter", "both")]
    [string]$Service = "both",
    [switch]$SkipBuild,
    [switch]$DeployOnly,
    [switch]$RunMigrations
)

$ErrorActionPreference = "Stop"

$ACCOUNT_ID   = "017091936354"
$REGION       = "us-east-1"
$PROJECT      = "fastapi-demo-sl"
$REGISTRY     = "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
$BACKEND_REPO = "$PROJECT/backend"
$BACKEND_IMG  = "$REGISTRY/$BACKEND_REPO`:latest"
$CLUSTER      = "$PROJECT-cluster"
$SERVICE      = "$PROJECT-api"
$TASK_FAMILY  = "$PROJECT-api"
$CONTAINER    = "api"
$BUCKET       = "$PROJECT-web-$ACCOUNT_ID"

function Log($msg)  { Write-Host "==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Err($msg)  { Write-Host "[ERR] $msg" -ForegroundColor Red; exit 1 }

$ROOT = Split-Path $PSScriptRoot -Parent
Set-Location $ROOT

# ============================================================
# BUILD + PUSH API IMAGE (skipped when -DeployOnly)
# ============================================================
if (-not $DeployOnly -and ($Service -eq "api" -or $Service -eq "both")) {
    Log "Logging in to ECR..."
    $token = aws ecr get-login-password --region $REGION
    docker login --username AWS --password $token $REGISTRY
    if ($LASTEXITCODE -ne 0) { Err "ECR login failed" }
    Ok "ECR login successful"

    if (-not $SkipBuild) {
        Log "Building API image..."
        docker build -f docker/Dockerfile.api -t $BACKEND_IMG api/
        if ($LASTEXITCODE -ne 0) { Err "API build failed" }
        Ok "API image built"
    }

    Log "Pushing API image..."
    docker push $BACKEND_IMG
    if ($LASTEXITCODE -ne 0) { Err "API push failed" }
    Ok "API image pushed"
}

# ============================================================
# MIGRATIONS (one-shot ECS run-task)
# ============================================================
if ($RunMigrations -and ($Service -eq "api" -or $Service -eq "both")) {
    Log "Running Alembic migrations as an ECS task..."
    $network = aws ecs describe-services --cluster $CLUSTER --services $SERVICE `
        --query "services[0].networkConfiguration" --output json
    $overrides = '{"containerOverrides":[{"name":"' + $CONTAINER + '","command":["alembic","upgrade","head"]}]}'
    $taskArn = aws ecs run-task --cluster $CLUSTER --task-definition $TASK_FAMILY `
        --launch-type FARGATE --network-configuration $network `
        --overrides $overrides --query "tasks[0].taskArn" --output text
    Log "Migration task: $taskArn"
    aws ecs wait tasks-stopped --cluster $CLUSTER --tasks $taskArn
    $exit = aws ecs describe-tasks --cluster $CLUSTER --tasks $taskArn `
        --query "tasks[0].containers[?name=='$CONTAINER'].exitCode | [0]" --output text
    if ($exit -ne "0") { Err "Migrations failed (exit $exit)" }
    Ok "Migrations completed"
}

# ============================================================
# DEPLOY API -> ECS (new task def revision + force-new-deployment)
# ============================================================
if ($Service -eq "api" -or $Service -eq "both") {
    Log "Registering new task definition revision..."
    $image = "$REGISTRY/$BACKEND_REPO`:latest"
    $defJson = aws ecs describe-task-definition --task-definition $TASK_FAMILY --query "taskDefinition" --output json
    $newDef = $defJson | jq --arg IMG "$image" --arg NAME "$CONTAINER" `
        '(.containerDefinitions[] | select(.name==$NAME) | .image) = $IMG | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)'
    $newDef | Out-File -FilePath "$ROOT\new-task-def.json" -Encoding utf8
    aws ecs register-task-definition --cli-input-json "file://$ROOT/new-task-def.json" | Out-Null
    Remove-Item "$ROOT\new-task-def.json" -Force

    Log "Forcing new ECS deployment..."
    aws ecs update-service --cluster $CLUSTER --service $SERVICE `
        --task-definition $TASK_FAMILY --force-new-deployment | Out-Null
    aws ecs wait services-stable --cluster $CLUSTER --services $SERVICE
    Ok "API deployment stable"
}

# ============================================================
# DEPLOY FLUTTER -> S3 + CloudFront
# ============================================================
if ($Service -eq "flutter" -or $Service -eq "both") {
    Log "Building Flutter web..."
    Set-Location "$ROOT\flutter"
    flutter pub get
    flutter build web --release --dart-define-from-file=config/prod-web.json
    if ($LASTEXITCODE -ne 0) { Err "Flutter build failed" }
    Set-Location $ROOT

    Log "Syncing to S3..."
    aws s3 sync "$ROOT\flutter\build\web" "s3://$BUCKET" --delete
    if ($LASTEXITCODE -ne 0) { Err "S3 sync failed" }

    Log "Invalidating CloudFront..."
    $distId = aws cloudfront list-distributions `
        --query "DistributionList.Items[?Comment=='$PROJECT — Flutter web + /api proxy'].Id | [0]" --output text
    aws cloudfront create-invalidation --distribution-id $distId --paths "/*" | Out-Null
    Ok "Flutter deployed and CloudFront invalidated"
}

Write-Host ""
Log "Done. App URL:"
aws cloudfront list-distributions `
    --query "DistributionList.Items[?Comment=='$PROJECT — Flutter web + /api proxy'].DomainName | [0]" --output text
