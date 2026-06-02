# ============================================================
# destroy-serverless.ps1 - Tear down the serverless stack.
#
# Unlike the EKS destroy (which had to manually delete the K8s
# namespace, wait for the LBC to remove the ALB, and clean orphan
# security groups), the serverless stack owns the ALB, S3 bucket and
# ECR in Terraform — so a single `terraform destroy` is clean.
#
# Usage: .\scripts\destroy-serverless.ps1
# ============================================================
$ErrorActionPreference = "Stop"

function Log($msg)  { Write-Host "==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }

Write-Host "[!] This will destroy the SERVERLESS stack (ECS/RDS/Redis/ALB/S3/CloudFront)!" -ForegroundColor Red
$confirm = Read-Host "Type 'yes' to confirm"
if ($confirm -ne "yes") { Write-Host "Cancelled."; exit 0 }

$tfDir = Join-Path $PSScriptRoot "..\terraform\serverless"
Set-Location $tfDir

Log "Running terraform destroy..."
terraform destroy -auto-approve
if ($LASTEXITCODE -ne 0) {
    Warn "terraform destroy had errors - check manually"
} else {
    Ok "Serverless stack destroyed!"
}

Set-Location (Join-Path $PSScriptRoot "..")
