// vars/terraformValidation.groovy (Jenkins Shared Library)
// Pipeline for validation on Pull Requests / Merge Requests
// Manual execution only - no automatic triggers

def call(Map config = [:]) {
    pipeline {
        agent {
            label 'terraform-agent'
        }
        
        parameters {
            string(
                name: 'GIT_REPO_URL',
                description: 'Git repository URL to validate'
            )
            string(
                name: 'GIT_BRANCH',
                defaultValue: 'main',
                description: 'Branch to validate'
            )
        }
        
        stages {
            stage('Checkout') {
                steps {
                    script {
                        echo "[CHECKOUT] Cloning repository: ${params.GIT_REPO_URL}"
                        echo "[CHECKOUT] Branch: ${params.GIT_BRANCH}"
                        
                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: params.GIT_BRANCH]],
                            userRemoteConfigs: [[
                                url: params.GIT_REPO_URL,
                                credentialsId: 'git-credentials'
                            ]]
                        ])
                    }
                }
            }
            
            stage('Format Check') {
                steps {
                    sh """
                        echo "[CHECK] Validating Terraform formatting"
                        terraform fmt -check -recursive || {
                            echo "[ERROR] Formatting issues found. Run 'terraform fmt -recursive' to fix."
                            exit 1
                        }
                        echo "[OK] Formatting check passed"
                    """
                }
            }
            
            stage('Terraform Validate') {
                steps {
                    sh """
                        echo "[VALIDATE] Initializing and validating Terraform"
                        terraform init -backend=false
                        terraform validate
                        echo "[OK] Validation passed"
                    """
                }
            }
            
            stage('Security Scan') {
                steps {
                    sh """
                        echo "[SCAN] Running TFSec security scan"
                        tfsec . --format junit --out tfsec-validation-report.xml || true
                        echo "[OK] Security scan completed"
                    """
                    // Phase 2: Add Checkov if needed
                    // sh "checkov -d . --framework terraform"
                }
            }
        }
        
        post {
            success {
                script {
                    echo "[SUCCESS] Validation passed for all checks"
                    
                    // Phase 2: GitLab MR comment
                    // updateGitlabCommitStatus name: 'terraform-validation', state: 'success'
                    // addGitLabMRComment comment: "[SUCCESS] Terraform validation passed"
                }
            }
            failure {
                script {
                    echo "[FAILURE] Validation failed. Check logs above."
                    
                    // Phase 2: GitLab MR comment
                    // updateGitlabCommitStatus name: 'terraform-validation', state: 'failed'
                    // addGitLabMRComment comment: "[ERROR] Terraform validation failed. Check build logs."
                }
            }
            always {
                junit "**/tfsec-validation-report.xml"
                cleanWs()
            }
        }
    }
}
