# EKS stack (Kubernetes on EKS + ALB + in-cluster Postgres/Redis)

The "full Kubernetes" alternative to the serverless stack. Provisions a real
EKS cluster and runs everything — API, Flutter web, Postgres and Redis — as
pods inside it. It never overlaps with the serverless stack: its own VPC
(`10.0.0.0/16`), its own ECR (`fastapi-demo/backend` + `fastapi-demo/frontend`),
everything namespaced `fastapi-demo-*`.

## Architecture

```
browser ─▶ ALB (internet-facing, HTTP via *.elb.amazonaws.com)
            ├─ /api, /docs, /redoc, /openapi.json → fastapi-service  (FastAPI, :8000)
            └─ /*                                  → flutter-service  (nginx, :80)
EKS cluster (k8s 1.32) on private subnets, 1× t3.small/medium node, single NAT
In-cluster: Postgres + Redis pods · ALB driven by AWS Load Balancer Controller
```

Unlike the serverless stack, **Postgres and Redis run as pods** (not RDS /
ElastiCache), the **Flutter frontend is a container in ECR** (not S3/CloudFront),
and there is **no HTTPS by default** — you get the raw ALB DNS name. The ALB is
created by the AWS Load Balancer Controller, which Terraform installs via Helm +
IRSA (see `helm_release.aws_lbc` in `main.tf`).

## Bootstrap order (important)

The k8s Deployments point at `:latest`, which does **not** exist in ECR on a
fresh stack — pods stay in `ImagePullBackOff` until the first image is pushed.
Bring it up in this order:

1. **Provision infra:**
   ```
   cd terraform/eks
   terraform init
   terraform apply
   ```
   Creates the VPC, EKS cluster + node group, both ECR repos, and the Load
   Balancer Controller (Helm).
2. **Configure kubectl** (the command is printed as the `configure_kubectl`
   output):
   ```
   aws eks update-kubeconfig --region us-east-1 --name fastapi-demo-cluster
   ```
3. **Fill in secrets**, then apply the manifests. Edit `k8s/01-secret.yaml` and
   replace every `CHANGE_ME_*` placeholder (see [Secrets](#secrets)), then:
   ```
   kubectl apply -f k8s/
   ```
   This creates the namespace, Secret, Postgres, Redis, both Deployments and the
   ALB Ingress.
4. **Build, push & roll out** the app images:
   ```
   ./scripts/deploy.ps1 -Service both -ApplyManifests   # Windows
   ./scripts/deploy.sh  both                            # Linux
   ```
   `deploy.ps1` logs in to ECR, builds + pushes the API and Flutter images, then
   `kubectl rollout restart`s the deployments. Use `-ApplyManifests` on the first
   run so `k8s/` is applied; omit it afterwards.
5. **Get the URL:**
   ```
   kubectl get ingress -n fastapi-demo
   ```
   The ALB takes a couple of minutes to come up after the Ingress is created.

> Tip: simplest cold start — `terraform apply` → fill secrets →
> `kubectl apply -f k8s/` → `./scripts/deploy.ps1 -Service both -ApplyManifests`.

## Secrets

Defined inline in `k8s/01-secret.yaml` as a single Opaque Secret
(`fastapi-demo-secret`) consumed by the FastAPI pods via `envFrom`. There is no
SSM / Secrets Manager here — you must replace the placeholders **before**
applying:

- `POSTGRES_PASSWORD` — Postgres password (matches the in-cluster Postgres pod)
- `SECRET_KEY` — `openssl rand -hex 32`
- `ADMIN_PASSWORD` — initial admin user password

Everything else (DB/Redis service names, CORS, `ENVIRONMENT`…) is non-secret
config living in the same manifest for convenience. Since it is committed to the
repo, keep real values out of git — apply locally or move to a sealed-secret /
external-secrets flow if this becomes more than a demo.

## Cost control

This stack is materially more expensive than serverless — it has an always-on
control plane and a node:

- **EKS control plane** ~$0.10/hr (~$73/mo) — billed while the cluster exists,
  there is no "pause".
- **Node** — 1× `t3.small`/`t3.medium` EC2 (`var.node_instance_type`,
  `desired_size = 1`).
- **NAT gateway** ~$32/mo, **ALB** ~$16/mo while the Ingress exists.

To stop paying, `terraform destroy` (see below). Scaling the node group to 0
still leaves the control plane, NAT and ALB billing, so it saves little.

## Teardown

EKS teardown is **not** a single `terraform destroy` — the ALB and its security
groups are created by the in-cluster Load Balancer Controller, not Terraform, so
they must be removed first or `terraform destroy` will hang on the VPC. Use the
helper script, which does it in the right order:

```
./scripts/destroy.ps1   # Windows  (prompts for 'yes')
./scripts/destroy.sh    # Linux
```

It: deletes the `fastapi-demo` namespace (triggers ALB teardown) → waits for /
force-deletes the ALB → cleans up orphan `k8s-*` security groups → runs
`terraform destroy`. If you tear down by hand, delete the namespace and wait for
the ALB to disappear **before** running `terraform destroy`.

> Contrast with the serverless stack, where every resource is Terraform-owned
> and teardown is a clean single `terraform destroy` with no manual pre-steps.
