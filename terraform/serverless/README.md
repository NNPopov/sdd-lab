# Serverless stack (ECS Fargate + RDS + ElastiCache + S3/CloudFront)

A fully self-contained alternative to the EKS stack. Brought up on a clean
environment, used, then destroyed. It never overlaps with the EKS stack —
its own VPC (`10.1.0.0/16`), its own ECR (`fastapi-demo-sl/backend`),
everything namespaced `fastapi-demo-sl-*`.

## Architecture

```
browser ─▶ CloudFront (HTTPS via *.cloudfront.net)
            ├─ /*      → S3 (Flutter web, private + OAC)
            └─ /api/*  → ALB (HTTP, locked to CloudFront) → ECS Fargate (FastAPI)
VPC: public subnets (ALB) | private subnets (ECS, RDS, Redis) | 1 NAT
RDS Postgres t3.micro · ElastiCache Redis t4g.micro · SSM Parameter Store
```

HTTPS is free from the default CloudFront certificate — no ACM / domain.
`config/prod-web.json` already uses `BASE_URL: "/api/v1"` (same-origin).

## Bootstrap order (important)

The ECS service is created pointing at `:latest`, which does **not** exist in
ECR on a fresh stack. So bring it up in this order:

1. **Build & push an image first** (CI `cd-serverless.yml` → `build-push`, or
   `./scripts/deploy-serverless.ps1 -Service api` after step 2 with the image
   already pushed). Alternatively set `ecs_desired_count = 0` for the first
   apply so no tasks try to start.
2. `terraform apply` (creates ECR, VPC, RDS, Redis, ALB, ECS, CloudFront).
3. Run **migrations** once: `cd-serverless.yml` with `run_migrations: true`,
   or `./scripts/deploy-serverless.ps1 -Service api -RunMigrations`.
4. **Deploy**: `cd-serverless.yml` → `build-push-deploy`, or the deploy script.

> Tip: simplest cold start —
> `terraform apply -var ecs_desired_count=0` → push image via CI → run the
> deploy workflow (it registers the task def revision and scales the rollout).

## Secrets

Generated in Terraform and stored as SSM `SecureString` under
`/fastapi-demo-sl/*`: `POSTGRES_PASSWORD`, `SECRET_KEY` (both random),
`ADMIN_PASSWORD` (from `var.admin_password`). The ECS execution role reads
them via the task definition `secrets` block. Non-secret config (DB/Redis
endpoints, CORS, ENVIRONMENT…) is passed as plain `environment`.

## Cost control

- Pause compute: `terraform apply -var ecs_desired_count=0` (or
  `aws ecs update-service --desired-count 0`).
- Stop RDS from the console/CLI to pay storage only.
- ALB still costs ~$16/mo while the stack exists — `terraform destroy` to
  pay nothing.

## Teardown

`./scripts/destroy-serverless.ps1` (or `.sh`) → single `terraform destroy`.
Clean: the ALB, S3 bucket (`force_destroy`) and ECR (`force_delete`) are all
Terraform-owned, so no orphaned resources and no manual pre-steps (unlike EKS).
