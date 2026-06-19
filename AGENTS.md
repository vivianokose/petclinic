# Petclinic Platform — Agent Instructions

## Two-Repo Architecture (CRITICAL — Read First)

This project uses a two-repo GitOps pattern:

| Repo | URL | Purpose | Can Agent Modify? |
|------|-----|---------|-------------------|
| petclinic | github.com/stephcloud/petclinic-platform | Infrastructure | ✅ YES |
| spring-petclinic-microservices | github.com/stephcloud/spring-petclinic-microservices | App source code | ❌ READ-ONLY |

### How the two repos work together

App repo CI builds images → pushes to ECR → fires dispatch to platform repo
Platform repo updates helm-values/ → ArgoCD detects → deploys to EKS

## Directory Layout

terraform/environments/{dev,prod}/
terraform/modules/{vpc,eks,ecr,rds,dns,secrets,observability,karpenter}/
helm/petclinic-service/
helm-values/
k8s/base/
k8s/argocd/install/
k8s/argocd/applications/{dev,prod}/
.github/workflows/
scripts/
docs/

## Technical Reference

Read docs/technical-spec.md before implementing any story.
Work backlog: docs/jira-backlog.md (17 epics).
Dependency chain: E-0 → E-1 → VPC → EKS → K8s → Helm → ArgoCD

## Terraform Conventions

- Provider: AWS ~> 5.0, region us-east-1
- State: S3 + DynamoDB, key: petclinic/{env}/terraform.tfstate
- Naming: petclinic-{env}-{resource}
- Tags: Project=petclinic, Environment={dev|prod}, ManagedBy=terraform
- Files per module: main.tf, variables.tf, outputs.tf, versions.tf
- Never hardcode secrets. Use sensitive = true for secret outputs.
- Run terraform fmt before committing. Run terraform validate after edits.

### Terraform Workflow
terraform fmt -recursive
terraform validate
terraform plan -out plan.out
terraform apply plan.out   # NEVER apply without a saved plan

## Kubernetes Conventions

- Namespaces: petclinic-dev, petclinic-prod
- Every resource MUST have labels: app.kubernetes.io/name, part-of=petclinic, managed-by=Helm
- Every Deployment MUST have readinessProbe and livenessProbe on /actuator/health endpoints
- Every container MUST have resource requests AND limits
- Image tags: commit SHA only, never latest
- Secrets: ExternalSecret CRs only, never in YAML

## Helm Conventions

- Single generic chart in helm/petclinic-service/ shared by all 8 services
- Per-service config in helm-values/{service}.yaml
- Per-env config in helm-values/{dev,prod}.yaml
- Validate: helm template + helm lint before committing
- ECR registry dev: 164885464623.dkr.ecr.us-east-1.amazonaws.com/petclinic-dev
- ECR registry prod: 164885464623.dkr.ecr.us-east-1.amazonaws.com/petclinic-prod

## ArgoCD Conventions

- CI pushes images. ArgoCD deploys. GitHub Actions NEVER runs kubectl apply.
- Dev: auto-sync (prune + self-heal)
- Prod: manual sync required
- 16 Applications total: 8 services x 2 environments

## CI/CD Pipeline Conventions

- CI in app repo. CD via ArgoCD watching platform repo.
- AWS auth: OIDC federation, never static credentials
- Image tags: commit SHA (7 chars), never latest
- Trivy scan after build, fail on CRITICAL CVEs
- GitHub Secrets: AWS_ROLE_ARN, AWS_REGION, AWS_ACCOUNT_ID, PLATFORM_REPO_TOKEN

## Security Rules (NON-NEGOTIABLE)

1. No secrets in code — use AWS Secrets Manager + External Secrets Operator
2. No public S3 buckets
3. No open security groups — no 0.0.0.0/0 except ALB on 80/443
4. Encryption everywhere — RDS, S3, EBS
5. Least privilege IAM — never */*
6. No terraform destroy without approval
7. No *.tfvars or .env files committed

## AWS Environment Details

| Setting | Dev | Prod |
|---------|-----|------|
| Region | us-east-1 | us-east-1 |
| Namespace | petclinic-dev | petclinic-prod |
| EKS nodes | 2x t4g.small ARM | 2x t4g.small ARM |
| RDS | db.t4g.micro | db.t4g.micro |
| Deploy | ArgoCD auto-sync | ArgoCD manual sync |

## Application Services (8 total)

| Service | Port | MySQL | Notes |
|---------|------|-------|-------|
| config-server | 8888 | No | Starts FIRST |
| discovery-server | 8761 | No | Starts SECOND |
| api-gateway | 8080 | No | Public-facing |
| customers-service | 8081 | Yes | |
| visits-service | 8082 | Yes | Deploy AFTER customers |
| vets-service | 8083 | Yes | Needs production profile |
| genai-service | 8084 | Optional | Needs OPENAI_API_KEY |
| admin-server | 9090 | No | |

## Safety Rules for Agent Actions

- NEVER run terraform destroy
- NEVER run rm -rf on terraform/, k8s/, helm/, .github/
- NEVER run terraform apply without a saved plan.out
- NEVER commit .env, .tfvars, .pem, .key files
- ALWAYS run terraform validate after editing .tf files
- ALWAYS run helm template to validate Helm changes

## Cost Reminder

Run ./scripts/stop-env.sh dev at end of every session.
EKS control plane costs ~$3.30/day even when idle.
