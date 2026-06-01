# ============================================================
# deploy.ps1 - Build, Push, Deploy to EKS
#
# Ispolzovaniye:
#   .\scripts\deploy.ps1 -Service both
#   .\scripts\deploy.ps1 -Service api
#   .\scripts\deploy.ps1 -Service flutter
#   .\scripts\deploy.ps1 -Service both -SkipBuild
#   .\scripts\deploy.ps1 -Service both -ApplyManifests
# ============================================================

param(
    [ValidateSet("api", "flutter", "both")]
    [string]$Service = "both",
    [switch]$SkipBuild,
    [switch]$ApplyManifests  # Primeniat k8s/ manifesty (tolko pri pervom deploye)
)

$ErrorActionPreference = "Stop"

# Konfiguratsiya
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

# Pereiti v koren monorepo
$ROOT = Split-Path $PSScriptRoot -Parent
Set-Location $ROOT

# 1. Login v ECR
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

# 4. Obnovit kubeconfig
Log "Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER
if ($LASTEXITCODE -ne 0) { Err "kubeconfig update failed" }
Ok "kubeconfig updated"

# 5. Primeniat manifesty (tolko esli -ApplyManifests)
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