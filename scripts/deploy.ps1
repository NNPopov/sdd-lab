# ============================================================
# deploy.ps1 - Build, Push, Deploy to EKS
#
# Usage:
#   .\scripts\deploy.ps1 -Service both                  # build + push + deploy
#   .\scripts\deploy.ps1 -Service api                   # only backend
#   .\scripts\deploy.ps1 -Service flutter               # only frontend
#   .\scripts\deploy.ps1 -Service both -SkipBuild       # push + deploy (no build)
#   .\scripts\deploy.ps1 -Service both -DeployOnly      # deploy only (no docker needed)
# ============================================================

param(
    [ValidateSet("api", "flutter", "both")]
    [string]$Service = "both",
    [switch]$SkipBuild,
    [switch]$DeployOnly,      # Skip build and push, only kubectl deploy
    [switch]$ApplyManifests   # Apply k8s/ manifests (first deploy only)
)

$ErrorActionPreference = "Stop"

$ACCOUNT_ID   = "017091936354"
$REGION       = "us-east-1"
$CLUSTER      = "fastapi-demo-cluster"
$NAMESPACE    = "fastapi-demo"
$REGISTRY     = "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
$BACKEND_IMG  = "$REGISTRY/fastapi-demo/backend:latest"
$FRONTEND_IMG = "$REGISTRY/fastapi-demo/frontend:latest"

function Log($msg)  { Write-Host "==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Err($msg)  { Write-Host "[ERR] $msg" -ForegroundColor Red; exit 1 }

# Go to monorepo root
$ROOT = Split-Path $PSScriptRoot -Parent
Set-Location $ROOT

# ============================================================
# DOCKER STEPS (skipped when -DeployOnly)
# ============================================================
if (-not $DeployOnly) {

    # 1. ECR Login
    Log "Logging in to ECR..."
    $token = aws ecr get-login-password --region $REGION
    docker login --username AWS --password $token $REGISTRY
    if ($LASTEXITCODE -ne 0) { Err "ECR login failed" }
    Ok "ECR login successful"

    # 2. Build
    if (-not $SkipBuild) {
        if ($Service -eq "api" -or $Service -eq "both") {
            Log "Building API image..."
            docker build -f docker/Dockerfile.api -t $BACKEND_IMG api/
            if ($LASTEXITCODE -ne 0) { Err "API build failed" }
            Ok "API image built"
        }

        if ($Service -eq "flutter" -or $Service -eq "both") {
            Log "Building Flutter image..."
            docker build -f docker/Dockerfile.flutter -t $FRONTEND_IMG .
            if ($LASTEXITCODE -ne 0) { Err "Flutter build failed" }
            Ok "Flutter image built"
        }
    }

    # 3. Push
    if ($Service -eq "api" -or $Service -eq "both") {
        Log "Pushing API image..."
        docker push $BACKEND_IMG
        if ($LASTEXITCODE -ne 0) { Err "API push failed" }
        Ok "API image pushed"
    }

    if ($Service -eq "flutter" -or $Service -eq "both") {
        Log "Pushing Flutter image..."
        docker push $FRONTEND_IMG
        if ($LASTEXITCODE -ne 0) { Err "Flutter push failed" }
        Ok "Flutter image pushed"
    }
}

# ============================================================
# KUBECTL STEPS (always run)
# ============================================================

# 4. Update kubeconfig
Log "Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER
if ($LASTEXITCODE -ne 0) { Err "kubeconfig update failed" }
Ok "kubeconfig updated"

# 5. Apply manifests (first deploy only, use -ApplyManifests flag)
if ($ApplyManifests) {
    Log "Applying K8s manifests..."
    kubectl apply -f k8s/
    if ($LASTEXITCODE -ne 0) { Err "kubectl apply failed" }
    Ok "K8s manifests applied"
}

# 6. Rollout restart
if ($Service -eq "api" -or $Service -eq "both") {
    Log "Restarting API deployment..."
    kubectl rollout restart deployment/fastapi-backend -n $NAMESPACE
    kubectl rollout status deployment/fastapi-backend -n $NAMESPACE --timeout=300s
    Ok "API deployment updated"
}

if ($Service -eq "flutter" -or $Service -eq "both") {
    Log "Restarting Flutter deployment..."
    kubectl rollout restart deployment/flutter-frontend -n $NAMESPACE
    kubectl rollout status deployment/flutter-frontend -n $NAMESPACE --timeout=300s
    Ok "Flutter deployment updated"
}

# 7. Status
Write-Host ""
Log "Current pods:"
kubectl get pods -n $NAMESPACE

Write-Host ""
Log "Ingress URL:"
kubectl get ingress -n $NAMESPACE
