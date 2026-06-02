# ============================================================
# destroy.ps1 - Bezopasnoye udaleniye vsego steka
# Ispolzovaniye: .\scripts\destroy.ps1
# ============================================================

$ErrorActionPreference = "Stop"

$REGION    = "us-east-1"
$CLUSTER   = "fastapi-demo-cluster"
$NAMESPACE = "fastapi-demo"

function Log($msg)  { Write-Host "==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }

# Podtverzhdenie
Write-Host "[!] This will destroy ALL resources!" -ForegroundColor Red
$confirm = Read-Host "Type 'yes' to confirm"
if ($confirm -ne "yes") { Write-Host "Cancelled."; exit 0 }

# 1. Obnovit kubeconfig
Log "Updating kubeconfig..."
$kubeResult = aws eks update-kubeconfig --region $REGION --name $CLUSTER 2>&1
if ($LASTEXITCODE -ne 0) {
    Warn "Could not connect to cluster - may already be deleted"
} else {
    # 2. Udalit namespace
    Log "Deleting K8s namespace '$NAMESPACE'..."
    kubectl delete namespace $NAMESPACE --ignore-not-found=true
    Ok "Namespace deleted - waiting for ALB cleanup..."

    # 3. Zhdem udaleniya ALB
    Log "Waiting for ALB cleanup (90 seconds)..."
    $wait = 90
    while ($wait -gt 0) {
        Start-Sleep 10
        $wait -= 10
        Write-Host "  $wait seconds remaining..."
        $albs = aws elbv2 describe-load-balancers --region $REGION `
            --query "LoadBalancers[?contains(LoadBalancerName, 'fastapid')].LoadBalancerName" `
            --output text 2>$null
        if ([string]::IsNullOrWhiteSpace($albs) -or $albs -eq "None") {
            Ok "ALB deleted!"
            $wait = 0
        }
    }

    # 4. Prinuditelnoye udaleniye ALB
    $albs = aws elbv2 describe-load-balancers --region $REGION `
        --query "LoadBalancers[?contains(LoadBalancerName, 'fastapid')].LoadBalancerArn" `
        --output text 2>$null

    if (-not [string]::IsNullOrWhiteSpace($albs) -and $albs -ne "None") {
        Warn "ALB still exists - deleting manually..."
        foreach ($arn in $albs.Split("`t")) {
            if ($arn.Trim() -and $arn.Trim() -ne "None") {
                aws elbv2 delete-load-balancer --load-balancer-arn $arn.Trim() --region $REGION
                Start-Sleep 15
            }
        }
    }

    # 5. Udalit orphan Security Groups
    Log "Cleaning up orphan Security Groups..."
    # Only delete SGs created by LBC (name starts with k8s-)
    # Skip eks-cluster-sg-* which is managed by Terraform
    $sgs = aws ec2 describe-security-groups --region $REGION `
        --filters "Name=tag:kubernetes.io/cluster/$CLUSTER,Values=owned" `
                  "Name=group-name,Values=k8s-*" `
        --query "SecurityGroups[].GroupId" `
        --output text 2>$null

    if (-not [string]::IsNullOrWhiteSpace($sgs) -and $sgs -ne "None") {
        foreach ($sg in $sgs.Split("`t")) {
            if ($sg.Trim() -and $sg.Trim() -ne "None") {
                Write-Host "  Deleting SG: $($sg.Trim())"
                aws ec2 delete-security-group --group-id $sg.Trim() --region $REGION 2>$null
            }
        }
    }
}

# 6. Terraform destroy
Log "Running terraform destroy..."
$terraformPath = Join-Path (Join-Path (Split-Path $PSScriptRoot -Parent) "terraform") "eks"
Set-Location $terraformPath
terraform destroy -auto-approve
if ($LASTEXITCODE -ne 0) {
    Warn "terraform destroy had errors - check manually"
} else {
    Ok "All resources destroyed!"
}

Set-Location (Join-Path $PSScriptRoot "..")