# Terraform Azure Architecture Plan

## Overview

Centralized Terraform framework for Azure infrastructure with shared pipelines and isolated project repositories.

## Core Strategy

### Isolated Project Repositories

Each project (power-bi, digital-cabin, etc.) has its own Git repository with complete Terraform code.

**Why:**

- Projects are independent and evolve at different speeds
- Teams can work without interfering with each other
- Simpler permissions per project
- Each repository is self-contained and deployable

**Structure per project:**
```
my-project/ (separate repository)
├── backend.tf
├── providers.tf
├── variables.tf
├── main.tf
├── outputs.tf
└── README.md
```

### Centralized Pipelines (4 Total)

Instead of creating 4 pipelines per project, we use 4 shared pipelines for ALL projects.

**Why:**

- Reduces maintenance: update once, applies to all projects
- Consistent deployment process across projects
- Easier to add new projects (just parameterize)
- Reduces Jenkins configuration overhead

**The 4 Pipelines:**

1. **terraform-deploy** - Deploy/destroy any project
   - Parameterized: PROJECT_NAME, ENVIRONMENT, ACTION
   - Works for any project in any environment

2. **terraform-validation** - Validate pull requests
   - Runs on all project repositories
   - Format, syntax, security (Trivy), cost analysis (Infracost)

3. **terraform-drift-detection** - Detect configuration drift
   - Scheduled (every 4 hours)
   - Checks all projects in all environments

4. **terraform-modules-validation** - Validate modules
   - Only runs on modules repository
   - Ensures module quality before release

### Versioned Modules

Terraform modules are in a separate repository with semantic versioning (v1.0.0, v1.1.0, etc.).

**Why versioning:**

- **Stability**: Projects reference specific versions (v1.0.0), won't break with module updates
- **Testing**: New module versions tested before projects update
- **Rollback**: Easy to revert to previous version if issues occur
- **Change control**: Clear what changed between versions (CHANGELOG.md)

**Example usage:**

```hcl
module "vnet" {
  source = "git@gitlab.com:org/terraform-azure-modules.git//modules/vnet?ref=v1.0.0"
  # ...
}
```

Projects choose when to upgrade: `ref=v1.0.0` → `ref=v1.1.0`

**Why use modules at all:**

- **Consistency**: Same network setup across all projects
- **Tested code**: Modules validated before use
- **Faster development**: Reuse instead of rewrite
- **Best practices**: Security and standards built-in
- **Easier maintenance**: Fix once, all projects benefit (when they upgrade)

## Backend Strategy

### One Storage Account, Three Containers

```
Storage Account: stterraformstate
├── terraform-state-prd
│   ├── power-bi/terraform.tfstate
│   ├── digital-cabin/terraform.tfstate
│   └── project-x/terraform.tfstate
├── terraform-state-qlt
└── terraform-state-tst
```

**Why this structure:**

- **Simple**: Flat structure, easy to understand and navigate
- **Isolated environments**: Each environment has its own container
- **Organized**: All projects grouped by environment
- **Scalable**: Works well up to 20+ projects
- **RBAC**: Service Principal per environment for security

**Why NOT one container per project:**

- More complex to manage (20 projects = 60 containers)
- Harder to navigate
- More configuration overhead
- Not needed for our scale

### Dynamic Backend Configuration

Projects have empty backend.tf, scripts inject configuration at runtime.

**Why:**

- **DRY**: Don't repeat backend config in every environment file
- **Flexible**: Same code works in any environment
- **Secure**: Backend details not hardcoded in repository

**How it works:**
```bash
# POC scripts handle configuration dynamically
cd scripts/poc
./azure-login.sh
./configure.sh my-project prd /path/to/workspace

# Generated backend-config.tfbackend:
# resource_group_name  = "rg-terraform-state"
# storage_account_name = "stterraformstate"
# container_name       = "terraform-state-prd"
# key                  = "my-project/terraform.tfstate"

terraform init -backend-config=backend-config.tfbackend
```

## Credentials Strategy

### Service Principal per Environment

Three Service Principals, one for each environment:

- sp-terraform-prd
- sp-terraform-qlt
- sp-terraform-tst

**Why separate SPs:**

- **Security**: Production credentials isolated from non-production
- **Least privilege**: Each SP only accesses its environment container
- **Audit**: Clear who deployed what and where
- **Risk reduction**: Compromised TST credentials can't affect PRD

**Why NOT one SP for all:**

- Security risk: single point of failure
- Can't restrict access by environment
- Audit trail less clear

### Credential Storage in Jenkins

Credentials stored in Jenkins as Secret Text, injected as environment variables.

**Per environment:**

```
azure-sp-prd-client-id
azure-sp-prd-client-secret
azure-sp-prd-subscription-id
azure-sp-prd-tenant-id
```

**Why:**

- Jenkins Credentials Plugin handles encryption
- Credentials not in code or logs
- Easy rotation without code changes
- Centralized management

## Docker Strategy

### Single Optimized Image

One Alpine-based Docker image (~500-550MB) with essential tools:

- Terraform 1.5.7
- Trivy 0.48.0
- Infracost 0.10.32
- Azure CLI
- Git
- Java 17 JRE
- Bash

**Why Alpine:**
- Small base image (5MB vs 72MB Ubuntu)
- Faster to pull and start
- Less attack surface
- Still has everything we need

**Why NOT multiple images:**

- Maintenance overhead
- Jenkins configuration complexity
- Not needed - same tools work for all projects

**Why these tools:**

- **Terraform**: Infrastructure provisioning
- **Trivy**: Multi-purpose security scanning with SARIF output
- **Infracost**: Real-time cost estimation and visibility
- **Azure CLI**: Authentication, validation, state management
- **Git**: Clone repositories
- **Java**: Jenkins agent runtime
- **Bash**: Script execution

**Tool selection rationale:**

- **Trivy over TFSec**: Better maintained, multi-purpose scanner, industry-standard SARIF output
- **Infracost addition**: Cost awareness during planning phase prevents surprises
- **Azure CLI**: Required for service principal auth and backend validation

Image size optimized while maintaining all necessary functionality.

## Multi-Environment Support

### Three Environments: PRD, QLT, TST

**PRD (Production):**

- Real workloads
- Approvals required (DevOps + Security teams)
- High availability configurations
- Production-grade resources

**QLT (Quality/Staging):**

- Pre-production testing
- Same config as PRD but smaller scale
- Approval recommended
- Integration testing

**TST (Test/Development):**

- Development and experimentation
- No approvals needed
- Lower-cost resources
- Rapid iteration

**Why three environments:**

- Standard software lifecycle: dev → staging → prod
- Balance between safety and speed
- Clear promotion path
- Cost optimization (TST/QLT use cheaper resources)

## Repository Strategy

### Two Repositories

**Repository 1: terraform-azure-project** (this repo)

- Purpose: Documentation, pipelines, scripts, templates
- Content: How to setup and use the framework
- Versioning: No tags, living documentation
- Audience: Platform team and developers

**Repository 2: terraform-azure-modules**

- Purpose: Reusable Terraform modules
- Content: vnet, subnet, nsg, vm-linux, etc.
- Versioning: Semantic versioning (v1.0.0, v1.1.0)
- Audience: All projects (as dependencies)

**Why separate:**

- **Different lifecycles**: Docs change frequently, modules need stability
- **Different versioning needs**: Modules need versions, docs don't
- **Clear purpose**: Framework vs modules
- **Independent CI/CD**: Module changes don't trigger doc builds

## Deployment Workflow

### Standard Flow

1. Developer clones project repository
2. Makes infrastructure changes
3. Creates pull request
4. **Validation pipeline** runs automatically (format, syntax, security)
5. PR approved and merged
6. Developer triggers **deploy pipeline** in Jenkins
7. Pipeline parameters: PROJECT_NAME=power-bi, ENVIRONMENT=tst, ACTION=plan
8. Jenkins pulls code, injects credentials for TST
9. Terraform plan executed, developer reviews
10. Developer runs again with ACTION=apply
11. Terraform applies changes
12. For QLT/PRD: approval gates activated
13. After approvals, infrastructure deployed

### Drift Detection Flow

1. **Drift pipeline** runs on schedule (every 4 hours)
2. For each project in each environment:
   - Run `terraform plan -detailed-exitcode`
   - Exit code 2 = drift detected
3. If drift found:
   - Send Teams notification
   - Log to Dynatrace
   - Create ticket (future)
4. Team investigates and remediates

## Security Approach

### State File Security

- **Encryption**: Azure Storage encryption at rest
- **Versioning**: Enabled (can restore previous states)
- **Soft delete**: 30-day retention
- **Access control**: Service Principal per environment
- **Locking**: Automatic via Azure Storage lease

### Code Security

- **TFSec scanning**: Every pull request
- **No hardcoded secrets**: All via Jenkins credentials
- **Input validation**: Variables have validation rules
- **Review required**: PRs need approval
- **Audit trail**: Git history + Jenkins logs

### Infrastructure Security

- **Least privilege**: Service Principals limited to environment
- **Network isolation**: VNETs per project
- **SSH only**: VMs use SSH keys, no passwords
- **HTTPS only**: Storage Account enforces HTTPS
- **TLS 1.2+**: Minimum TLS version enforced

## Scaling Strategy

### Current Scale (0-20 projects)

- Flat container structure
- Single storage account
- Four shared pipelines
- Works efficiently

### Future Scale (20+ projects)

If needed, can evolve to:
```
terraform-state-prd/
├── apps/power-bi/terraform.tfstate
├── data/analytics/terraform.tfstate
└── infra/networking/terraform.tfstate
```

But not needed now (YAGNI - You Aren't Gonna Need It).

## Benefits Summary

### For Developers

- Start new projects in minutes (copy template)
- Don't worry about backend setup
- Consistent deployment process
- Self-service via Jenkins
- Safe to experiment in TST

### For Platform Team

- Maintain 4 pipelines instead of 4×N
- Central security and compliance
- Easy to update standards (upgrade modules)
- Clear audit trail
- Automated drift detection

### For Organization

- Faster time to market
- Reduced infrastructure errors
- Cost visibility per project
- Security by default
- Knowledge sharing via modules

## What We Avoided

### Common Anti-Patterns We Don't Do

**Monorepo with all projects** - Hard to manage permissions, slow CI/CD
**Pipeline per project** - Maintenance nightmare with many projects
**Hardcoded backend config** - Not flexible, not DRY
**Modules without versions** - Projects break when modules change
**Single environment** - Can't test safely
**Manual deployments** - Error-prone, no audit trail
**Shared state files** - Locking conflicts, blast radius
**One SP for everything** - Security risk

## Success Metrics

How we know it's working:

- **Speed**: New project deployed in < 1 hour
- **Safety**: Zero production incidents from drift
- **Adoption**: All teams using standard pipelines
- **Quality**: < 5% PR validation failures
- **Efficiency**: < 2 hours/week pipeline maintenance

## Next Steps

1. Setup Azure backend (storage + service principals)
2. Build Docker image for Jenkins
3. Configure Jenkins with credentials and Docker cloud
4. Create terraform-azure-modules repository with v1.0.0
5. Deploy first project (POC)
6. Train teams on workflow
7. Monitor and improve

---

**Key Principle**: Keep it simple. Add complexity only when proven necessary.
