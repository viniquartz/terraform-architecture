// Jenkins Pipeline Job - Terraform Validation
// Copy this script directly into Jenkins Pipeline job configuration
// Use for Pull Request validation before merging code

pipeline {
    agent {
        docker {
            image 'jenkins-terraform:latest'
            label 'terraform-agent'
            args '--network host'
            reuseNode true
        }
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
                    echo "[SCAN] Running Trivy security scan"
                    trivy config . \\
                        --format sarif \\
                        --output trivy-validation-report.sarif \\
                        --severity MEDIUM,HIGH,CRITICAL || true
                    
                    echo "[SCAN] Converting SARIF to JUnit format"
                    trivy convert --format template --template '@contrib/junit.tpl' \\
                        trivy-validation-report.sarif > trivy-validation-report.xml || true
                    
                    echo "[OK] Security scan completed"
                """
            }
        }
        
        stage('Cost Estimation') {
            steps {
                sh """
                    echo "[COST] Running Infracost estimation"
                    
                    # Initialize for cost calculation
                    terraform init -backend=false
                    
                    # Generate cost breakdown
                    infracost breakdown \\
                        --path . \\
                        --format json \\
                        --out-file infracost-validation.json || true
                    
                    # Generate HTML report
                    infracost output \\
                        --path infracost-validation.json \\
                        --format html \\
                        --out-file infracost-validation.html || true
                    
                    # Show summary
                    echo "[COST] Cost Summary:"
                    infracost output \\
                        --path infracost-validation.json \\
                        --format table || true
                    
                    echo "[OK] Cost estimation completed"
                """
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
            // Archive reports
            archiveArtifacts artifacts: '**/*-report.*,**/*-validation.*', allowEmptyArchive: true
            
            // Publish JUnit test results
            junit testResults: '**/*-report.xml', allowEmptyResults: true
            
            // Publish HTML reports
            publishHTML([
                allowMissing: true,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: '.',
                reportFiles: 'infracost-validation.html',
                reportName: 'Infracost Report'
            ])
            
            cleanWs()
        }
    }
}
