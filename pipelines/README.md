# Jenkins Pipelines - Terraform Azure

Jenkins pipelines for managing Terraform infrastructure on Azure using ephemeral Docker containers.

## Available Pipelines

| Pipeline | File | Trigger | Approval | Purpose |
|----------|------|---------|----------|---------|
| Deploy | `terraform-deploy-job.groovy` | Manual | Yes | Deploy resources (plan/apply) |
| Destroy | `terraform-destroy-job.groovy` | Manual | Yes | Destroy resources |
| Validation | `terraform-validation-job.groovy` | Manual | No | Validate project code |
| Drift Detection | `terraform-drift-detection-job.groovy` | Auto (4h) | No | Detect infrastructure drift |
| Modules Validation | `terraform-modules-validation-job.groovy` | Manual | No | Validate shared modules |

**Note:** Modules validation is only needed if you maintain a separate Terraform modules repository. If not, you can skip this pipeline.

---

## Quick Setup

### 1. Configure Jenkins Credentials

Go to: Manage Jenkins > Credentials > Add Credentials

**Azure Service Principals (per environment):**

```
Type: Secret text

azure-sp-prd-client-id
azure-sp-prd-client-secret
azure-sp-prd-subscription-id
azure-sp-prd-tenant-id

azure-sp-qlt-client-id
azure-sp-qlt-client-secret
azure-sp-qlt-subscription-id
azure-sp-qlt-tenant-id

azure-sp-tst-client-id
azure-sp-tst-client-secret
azure-sp-tst-subscription-id
azure-sp-tst-tenant-id
```

**Git Credentials:**

```
Type: Username with password
ID: git-credentials
Username: your-git-username
Password: your-PAT-token
```

**Test Configuration:**

Create a test pipeline:

```groovy
pipeline {
    agent {
        label 'terraform-agent'
    }
    stages {
        stage('Test') {
            steps {
                sh 'terraform version'
                sh 'trivy --version'
                sh 'infracost --version'
                sh 'az version'
                sh 'hostname'
            }
        }
    }
}
```

Run and verify:

- Container is created automatically
- Commands execute successfully
- Container is destroyed after completion

**Important:** The pipeline will automatically create and destroy containers for each build.

### 5. Create Jenkins Jobs

For each pipeline:

1. New Item > Name (e.g., `terraform-deploy`) > Pipeline > OK
2. Pipeline section:
   - Definition: Pipeline script
   - Script: Copy content from corresponding `.groovy` file
   - Use Groovy Sandbox: checked
3. Save

**Expected Behavior:**

When you run any pipeline:

1. Jenkins receives build request
2. Jenkins requests Docker cloud to provision agent with label `terraform-agent`
3. Docker cloud creates container from `jenkins-terraform:latest` image
4. Container starts and connects to Jenkins
5. Pipeline stages execute inside container
6. Artifacts are copied to Jenkins master
7. Pipeline completes
8. Container is automatically destroyed
9. Volumes and temporary files are cleaned up

**Verify Ephemeral Behavior:**

During pipeline execution, on Docker VM:

```bash
# Watch containers being created/destroyed
watch -n 1 'docker ps'

# During execution you'll see:
# CONTAINER ID   IMAGE                        STATUS
# abc123def456   jenkins-terraform:latest     Up 5 seconds

# After completion - container disappears
```

---

## Pipeline Details

### 1. Deploy Pipeline

**File:** `terraform-deploy-job.groovy`

Deploys Terraform resources to Azure environments.

**Parameters:**

- `PROJECT_NAME`: Project name
- `ENVIRONMENT`: prd, qlt, or tst
- `ACTION`: plan or apply
- `GIT_BRANCH`: Git branch (default: main)
- `GIT_REPO_URL`: Repository URL

**Stages:**

1. Initialize
2. Checkout
3. Validate (format, syntax)
4. Security Scan (Trivy)
5. Cost Estimation (Infracost)
6. Terraform Init
7. Terraform Plan
8. Approval (if apply)
9. Terraform Apply

**Approvals:**

- TST/QLT: devops-team (2 hours)
- PRD: devops-team + security-team (4 hours)

**Artifacts:** tfplan JSON, Trivy report, Infracost report

---

### 2. Destroy Pipeline

**File:** `terraform-destroy-job.groovy`

Destroys all Terraform resources for a project.

**Parameters:**

- `PROJECT_NAME`: Project name
- `ENVIRONMENT`: prd, qlt, or tst
- `GIT_BRANCH`: Git branch (default: main)
- `GIT_REPO_URL`: Repository URL

**Stages:**

1. Initialize
2. Checkout
3. Terraform Init
4. Terraform Plan -destroy
5. Approval (mandatory with confirmation)
6. Terraform Destroy

**Approvals:**

- TST/QLT: devops-team (4 hours)
- PRD: devops-team + security-team (8 hours)
- Requires explicit confirmation checkbox

**Warning:** This permanently deletes all resources. Always review the destroy plan carefully.

---

### 3. Validation Pipeline

**File:** `terraform-validation-job.groovy`

Validates Terraform project code before merging Pull Requests.

**Parameters:**

- `GIT_REPO_URL`: Repository URL
- `GIT_BRANCH`: Branch to validate

**Stages:**

1. Checkout
2. Format Check
3. Terraform Validate
4. Security Scan (Trivy)
5. Cost Estimation (Infracost)

**Use cases:**

- Pre-merge PR validation
- Code review
- Quick syntax verification

**Artifacts:** Trivy report, Infracost report

---

### 4. Drift Detection Pipeline

**File:** `terraform-drift-detection-job.groovy`

Automatically detects infrastructure drift across all projects.

**Parameters:**

- `PROJECTS_LIST`: Comma-separated project names
- `GIT_ORG`: Git organization/username

**Trigger:** Automatic every 4 hours (`H */4 * * *`)

**Stages:**

1. For each project/environment:
   - Checkout
   - Init with backend
   - Plan with detailed-exitcode
   - Detect drift (exit code 2)

**Output:**

- SUCCESS: No drift detected
- UNSTABLE: Drift detected (check artifacts)
- Artifacts: drift-plan JSON for affected projects

**Note:** Update `PROJECTS_LIST` with your actual projects before first run.

---

### 5. Modules Validation Pipeline

**File:** `terraform-modules-validation-job.groovy`

Validates Terraform modules repository before versioning.

**Parameters:**

- `MODULE_REPO_URL`: Modules repository URL
- `GIT_BRANCH`: Branch to validate

**Stages:**

1. Checkout
2. Validate All Modules
3. Security Scan (Trivy)
4. Cost Analysis (examples)
5. Validate Examples
6. Version Check
7. Quality Report

**Quality checks:**

- Format and syntax
- README.md presence
- examples/ directory
- variables.tf, outputs.tf
- Example validation

**Note:** Only needed if you maintain a separate Terraform modules repository.
