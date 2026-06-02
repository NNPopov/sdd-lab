# Deployment

The app can be deployed to AWS via **two independent, non-overlapping stacks**.
Pick one — they each provision their own VPC, ECR and resources and never share
state, so you can stand one up, tear it down, and try the other.

| | **EKS stack** | **Serverless stack** |
|---|---|---|
| Compute | Kubernetes on EKS (managed node group) | ECS Fargate (no servers) |
| Frontend | Flutter image (nginx) as a pod | Flutter web on S3 + CloudFront |
| Database | Postgres **pod** in-cluster | RDS Postgres (managed) |
| Cache | Redis **pod** in-cluster | ElastiCache Redis (managed) |
| Ingress | ALB via AWS Load Balancer Controller | CloudFront → ALB |
| TLS | none by default (raw ALB DNS) | free HTTPS (CloudFront cert) |
| VPC CIDR | `10.0.0.0/16` | `10.1.0.0/16` |
| Namespace | `fastapi-demo-*` | `fastapi-demo-sl-*` |
| Terraform | [`terraform/eks/`](terraform/eks/) | [`terraform/serverless/`](terraform/serverless/) |
| Rough cost | higher — always-on control plane + node + NAT + ALB | lower — pay-per-use, single NAT + ALB |
| Teardown | multi-step (ALB/SG cleanup, then destroy) | clean single `terraform destroy` |

> **TL;DR:** want the cheaper, simpler-to-tear-down option → **serverless**.
> Want to actually run/learn Kubernetes → **EKS**.

## Prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/) configured with credentials
- [Terraform](https://developer.hashicorp.com/terraform) ≥ 1.5
- [Docker](https://www.docker.com/) (the daemon must be **running** before any build)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (for the web/image build)
- **EKS only:** [`kubectl`](https://kubernetes.io/docs/tasks/tools/) and
  [`helm`](https://helm.sh/)

> On Windows the scripts run under PowerShell 5.1; on Linux/macOS use the `.sh`
> variants under `pwsh` or bash. The scripts are cross-platform equivalents.

## EKS stack

Full Kubernetes: a real EKS cluster running API, Flutter, Postgres and Redis as
pods, exposed through an ALB.

**Full guide:** [`terraform/eks/README.md`](terraform/eks/README.md)

Short version:

```bash
cd terraform/eks && terraform init && terraform apply   # VPC, EKS, ECR, LBC
aws eks update-kubeconfig --region us-east-1 --name fastapi-demo-cluster
# edit k8s/01-secret.yaml (replace CHANGE_ME_*), then:
kubectl apply -f k8s/
```

Build, push & roll out the app images:

| OS | Command |
|---|---|
| Windows | [`scripts/deploy.ps1`](scripts/deploy.ps1) `-Service both -ApplyManifests` |
| Linux/macOS | [`scripts/deploy.sh`](scripts/deploy.sh) `both` |

Get the URL: `kubectl get ingress -n fastapi-demo`.

**Teardown** (deletes the namespace, waits for ALB/SG cleanup, then
`terraform destroy`):

| OS | Command |
|---|---|
| Windows | [`scripts/destroy.ps1`](scripts/destroy.ps1) |
| Linux/macOS | [`scripts/destroy.sh`](scripts/destroy.sh) |

## Serverless stack

ECS Fargate for the API + S3/CloudFront for the Flutter web app, with managed
RDS and ElastiCache. Free HTTPS from the default CloudFront certificate.

**Full guide:** [`terraform/serverless/README.md`](terraform/serverless/README.md)

Short version (mind the [bootstrap order](terraform/serverless/README.md#bootstrap-order-important)
— ECS references `:latest`, which doesn't exist on a fresh stack):

```bash
cd terraform/serverless && terraform init
terraform apply -var ecs_desired_count=0   # cold start: no tasks try to pull yet
```

Build, push, migrate & deploy:

| OS | Command |
|---|---|
| Windows | [`scripts/deploy-serverless.ps1`](scripts/deploy-serverless.ps1) `-Service both` |
| Linux/macOS | [`scripts/deploy-serverless.sh`](scripts/deploy-serverless.sh) `both` |

Run migrations once: add `-RunMigrations` (PowerShell) — an Alembic
`upgrade head` as a one-shot ECS task.

**Teardown** (single clean `terraform destroy`):

| OS | Command |
|---|---|
| Windows | [`scripts/destroy-serverless.ps1`](scripts/destroy-serverless.ps1) |
| Linux/macOS | [`scripts/destroy-serverless.sh`](scripts/destroy-serverless.sh) |

## CI/CD (GitHub Actions)

All deploy workflows are **manual** (`workflow_dispatch`) and share the same
`action` choices: `build-only`, `build-push`, `build-push-deploy`, `deploy-only`
(plus a `service` and a `run_migrations` toggle).

| Workflow | Purpose |
|---|---|
| [`ci.yml`](.github/workflows/ci.yml) | Build images and push to ECR (on push / PR / manual) |
| [`cd.yml`](.github/workflows/cd.yml) | Deploy to the **EKS** stack |
| [`cd-serverless.yml`](.github/workflows/cd-serverless.yml) | Deploy to the **serverless** stack |
| [`migrations.yml`](.github/workflows/migrations.yml) | Run Alembic `upgrade head` |
