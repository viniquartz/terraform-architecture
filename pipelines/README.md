# Terraform Pipelines - Quick Guide

This directory contains all Jenkins pipelines (Shared Library) for Terraform infrastructure management.

## Available Pipelines

### 1. terraform-deploy-pipeline.groovy
**Main pipeline for resource deployment and destroy**

- **Execution:** Manual only - no automatic triggers
- **Parameters:** PROJECT_NAME, ENVIRONMENT, ACTION, GIT_BRANCH, GIT_REPO_URL
- **Backend:** Dynamic configuration (injected at runtime)
- **Credentials:** Environment-specific Service Principals (azure-sp-{env}-*)
- **Security:** Trivy security scanning (SARIF output)
- **Cost Analysis:** Infracost cost estimation (HTML reports)
- **Approvals:** Jenkins-based (DevOps Team + Security Team for PRD)
- **Usage:** Deploy/destroy any project in any environment

### 2. terraform-validation-pipeline.groovy
**Code validation for Pull Requests**

- **Execution:** Manual only - no automatic triggers
- **Parameters:** GIT_REPO_URL, GIT_BRANCH
- **Validation:** Format check, syntax validation, security scan (Trivy), cost analysis (Infracost)
- **Usage:** Run before merging code changes

### 3. terraform-drift-detection-pipeline.groovy
**Scheduled drift detection across all projects**

- **Execution:** Automatic (cron: every 4 hours) - ONLY pipeline with automatic trigger
- **Parameters:** PROJECTS_LIST (comma-separated)
- **Backend:** Dynamic configuration per environment
- **Credentials:** Environment-specific Service Principals
- **Scope:** All projects in all environments (prd, qlt, tst)
- **Usage:** Continuous infrastructure drift monitoring

### 4. terraform-modules-validation-pipeline.groovy
**Validation for Terraform modules repository**

- **Execution:** Manual only - no automatic triggers
- **Parameters:** MODULE_REPO_URL, GIT_BRANCH
- **Validation:** Format, syntax, security (Trivy), cost analysis (Infracost), examples validation
- **Quality:** Checks for README, validates example code
- **Usage:** Quality gate for modules before versioning

## Phase 2 Features (Commented Out)

All pipelines have Phase 2 features commented out and ready for future implementation:

### sendTeamsNotification.groovy
Sends formatted notifications to Microsoft Teams (Phase 2).

**Future notifications:**
- Deploy started/completed
- Pending approvals
- Drift detected
- Validation results

### sendDynatraceEvent.groovy
Sends events and metrics to Dynatrace (Phase 2).

**Future metrics:**
- Pipeline duration and status
- Drift detection events
- Deployment tracking

## Jenkins Installation

### 1. Create Jenkins Shared Library

In Jenkins: Manage Jenkins → Configure System → Global Pipeline Libraries

- Name: `terraform-pipelines`
- Default version: `main`
- Project repository: Your Jenkins shared library repository
- Credentials: `git-credentials`

### 2. Shared Library Repository Structure

Place these pipeline files in the `vars/` directory:

```text
jenkins-shared-library/
├── vars/
│   ├── terraformDeploy.groovy
│   ├── terraformValidation.groovy
│   ├── terraformDriftDetection.groovy
│   ├── terraformModulesValidation.groovy
│   ├── sendTeamsNotification.groovy      (Phase 2)
│   └── sendDynatraceEvent.groovy         (Phase 2)
└── README.md
```

### 3. Configure Credentials in Jenkins

**Required Now:**

Manage Jenkins → Credentials → Add Credentials (Secret Text)

**Per Environment (PRD, QLT, TST):**
- `azure-sp-prd-client-id` / `azure-sp-qlt-client-id` / `azure-sp-tst-client-id`
- `azure-sp-prd-client-secret` / `azure-sp-qlt-client-secret` / `azure-sp-tst-client-secret`
- `azure-sp-prd-subscription-id` / `azure-sp-qlt-subscription-id` / `azure-sp-tst-subscription-id`
- `azure-sp-prd-tenant-id` / `azure-sp-qlt-tenant-id` / `azure-sp-tst-tenant-id`

**Git Access:**
- `git-credentials`: Git access token or SSH key

**Phase 2:**
- `teams-webhook-url`: Microsoft Teams Incoming Webhook
- `dynatrace-url`: Dynatrace environment URL
- `dynatrace-api-token`: Dynatrace API token

### 4. Create Jenkins Jobs

#### Job 1: Terraform Deploy (Parameterized Job)

```groovy
@Library('terraform-pipelines') _

terraformDeploy()
```

Configuration: Pipeline job with parameters (manual execution only)

#### Job 2: Terraform Validation (Pipeline Job)

```groovy
@Library('terraform-pipelines') _

terraformValidation()
```

Configuration: Pipeline job with parameters (manual execution only)

#### Job 3: Terraform Drift Detection (Pipeline Job)

```groovy
@Library('terraform-pipelines') _

terraformDriftDetection()
```

Configuration: Pipeline job with cron trigger (H */4 * * *)

#### Job 4: Terraform Modules Validation (Pipeline Job)

```groovy
@Library('terraform-pipelines') _

terraformModulesValidation()
```

Configuration: Pipeline job with parameters (manual execution only)

## Security

### Approval Permissions

Configure in Jenkins: Manage Jenkins → Configure Global Security → Authorization

**Role-Based Strategy:**

- **devops-team**: Can approve TST, QLT, PRD deployments
- **security-team**: Can approve PRD deployments (additional layer)

Assign users to these roles in Jenkins authorization matrix.

## Usage Examples

### Deploy a Project

1. Open "Terraform Deploy" job in Jenkins
2. Click "Build with Parameters"
3. Fill parameters:
   - PROJECT_NAME: `power-bi`
   - ENVIRONMENT: `prd`
   - ACTION: `plan`
   - GIT_BRANCH: `main`
   - GIT_REPO_URL: `git@github.com:org/power-bi.git`
4. Click "Build" - pipeline runs plan
5. Review plan output
6. Run again with ACTION: `apply`
7. Approve when prompted (devops-team + security-team for PRD)
8. Infrastructure deployed

### Validate Code Before Merge

1. Open "Terraform Validation" job
2. Click "Build with Parameters"
3. Fill parameters:
   - GIT_REPO_URL: `git@github.com:org/my-project.git`
   - GIT_BRANCH: `feature/my-changes`
4. Click "Build"
5. Review validation results (format, syntax, security)
6. Fix any issues before merging

### Check Drift Detection Results

1. Open "Terraform Drift Detection" job
2. View last execution results
3. Check console output for drift warnings
4. Pipeline runs automatically every 4 hours
5. Update PROJECTS_LIST parameter as needed

## Phase 2 Features

When ready to implement notifications and monitoring:

1. Uncomment Teams/Dynatrace code in pipeline files
2. Add webhook URLs and API tokens to Jenkins credentials
3. Configure Dynatrace dashboards
4. Test notifications

## Additional Documentation

- [Setup Guide](../docs/SETUP.md)
- [Backend Configuration](../docs/BACKEND.md)
- [Architecture Plan](../docs/architecture-plan.md)
- [Docker Image](../docker/README.md)

---

**Last Updated:** December 2025
