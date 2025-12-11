# Terraform Pipelines - Quick Guide

This directory contains all Jenkins pipelines (Shared Library) for Terraform infrastructure management.

## Available Pipelines

### 1. terraform-deploy-pipeline.groovy
**Main pipeline for resource deployment and destroy**

- **Parameters:** PROJECT_NAME, ENVIRONMENT, ACTION, GIT_BRANCH
- **Approvals:** DevOps Team (all) + Security Team (prod)
- **Integrations:** Teams + Dynatrace
- **Usage:** Deploy/destroy individual projects

### 2. terraform-validation-pipeline.groovy
**Automatic validation on Pull/Merge Requests**

- **Trigger:** Automatic on MRs
- **Validation:** Parallel across all environments
- **Integrations:** GitLab (status + comments)
- **Usage:** Quality gate for MRs

### 3. terraform-drift-detection-pipeline.groovy
**Scheduled drift detection**

- **Trigger:** Cron (every 4 hours)
- **Scope:** All projects and environments
- **Integrations:** Teams + Dynatrace (only when drift)
- **Usage:** Continuous monitoring

### 4. terraform-modules-validation-pipeline.groovy
**Monorepo module validation**

- **Trigger:** Push and MRs on modules repo
- **Validation:** Format, syntax, security, tests
- **Quality Gates:** README required, tests recommended
- **Usage:** Quality gate for modules

## Helper Functions

### sendTeamsNotification.groovy
Sends formatted notifications to Microsoft Teams.

**Parameters:**
- `status`: STARTED | SUCCESS | FAILURE | PENDING_APPROVAL | DRIFT_DETECTED
- `projectName`: Project name
- `environment`: Target environment
- `action`: Action being executed
- `buildUrl`: Link to Jenkins build

### sendDynatraceEvent.groovy
Sends events and metrics to Dynatrace.

**Metrics sent:**
- `terraform.pipeline.duration`: Pipeline duration
- `terraform.pipeline.status`: Status (1=success, 0=failure)
- `terraform.drift.detected`: Drift detected

## Jenkins Installation

### 1. Create Jenkins Shared Library

```groovy
// In Jenkins: Manage Jenkins → Configure System → Global Pipeline Libraries

Name: terraform-pipelines
Default version: main
Project repository: https://gitlab.com/org/jenkins-shared-library.git
Credentials: gitlab-credentials
```

### 2. Shared Library Repository Structure

```
jenkins-shared-library/
├── vars/
│   ├── terraformDeploy.groovy
│   ├── terraformValidation.groovy
│   ├── terraformDriftDetection.groovy
│   ├── terraformModulesValidation.groovy
│   ├── sendTeamsNotification.groovy
│   └── sendDynatraceEvent.groovy
└── README.md
```

### 3. Configure Credentials in Jenkins

```
Manage Jenkins → Credentials → Add Credentials

- azure-client-id: Azure Service Principal Client ID
- azure-client-secret: Azure Service Principal Secret
- azure-subscription-id: Azure Subscription ID
- azure-tenant-id: Azure Tenant ID
- gitlab-credentials: GitLab personal access token
- teams-webhook-url: Microsoft Teams Incoming Webhook URL
- dynatrace-url: Dynatrace environment URL
- dynatrace-api-token: Dynatrace API token
```

### 4. Create Jenkins Jobs

#### Job 1: Terraform Deploy (Parameterized)

```groovy
@Library('terraform-pipelines') _

terraformDeploy()
```

#### Job 2: Terraform Validation (MultiBranch Pipeline)

```groovy
@Library('terraform-pipelines') _

terraformValidation()
```

#### Job 3: Terraform Drift Detection (Scheduled)

```groovy
@Library('terraform-pipelines') _

terraformDriftDetection()
```

#### Job 4: Terraform Modules Validation (MultiBranch Pipeline)

```groovy
@Library('terraform-pipelines') _

terraformModulesValidation()
```

## Security

### Approval Permissions

```groovy
// Configure in Jenkins: Manage Jenkins → Configure Global Security

Role-Based Authorization:

devops-team:
  - members: ['user1@company.com', 'user2@company.com']
  - permissions: ['Job.Build', 'Job.Cancel', 'Job.Read']

security-team:
  - members: ['security1@company.com', 'security2@company.com']
  - permissions: ['Job.Build', 'Job.Cancel', 'Job.Read']
```

## Monitoring

### Dynatrace Dashboards

Metrics available for dashboard:
- `terraform.pipeline.duration` per project/environment
- `terraform.pipeline.status` success rate
- `terraform.drift.detected` drift events
- `terraform.resources.count` managed resources

### Teams Notifications

Notified events:
- Deploy started
- Pending approvals
- Deploy completed (success/failure)
- Drift detected
- Validation failures

## Usage Example

### Deploy a Project

1. Access "Terraform Deploy" job
2. Click "Build with Parameters"
3. Fill in:
   - PROJECT_NAME: `project-a`
   - ENVIRONMENT: `production`
   - ACTION: `apply`
   - GIT_BRANCH: `main`
4. Click "Build"
5. Wait for DevOps Team approval
6. Wait for Security Team approval (prod)
7. Deploy will execute

### Validate a Module

1. Checkout branch
2. Make changes to module
3. Commit and push
4. Create Merge Request
5. Validation pipeline executes automatically
6. Result appears as status on MR

## Additional Documentation

- [Complete Setup Guide](../docs/SETUP-TRACKING.md)
- [Backend Administration](../docs/BACKEND-ADMIN.md)
- [Docker README](../docker/README.md)

---

**Last Updated:** December 2025  
**Maintained By:** DevOps Team
