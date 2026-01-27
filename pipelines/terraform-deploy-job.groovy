// Jenkins Pipeline Job - Terraform Deploy
// Copy this script directly into Jenkins Pipeline job configuration

pipeline {
    agent {
        docker {
            image 'jenkins-terraform:v1.0.0'
            label 'terraform-agent'
            args '-u jenkins:jenkins --network host -v /var/run/docker.sock:/var/run/docker.sock -v /home/jenkins/trivy_cache:/home/jenkins/.cache/trivy -e HOME=/home/jenkins -e AZURE_CONFIG_DIR=/home/jenkins/.azure'
            reuseNode true
        }
    }
    
    parameters {
        string(
            name: 'PROJECT_NAME',
            description: 'Project name (e.g., power-bi, digital-cabin)'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['tst', 'qlt', 'prd'],
            description: 'Target environment'
        )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply'],
            description: 'Terraform action'
        )
        string(
            name: 'GIT_REPO_URL',
            description: 'Full Git repository URL'
        )
        string(
            name: 'GIT_BRANCH',
            defaultValue: 'main',
            description: 'Repository branch'
        )
    }
    
    environment {
        PROJECT_DISPLAY_NAME = "${params.PROJECT_NAME}-${params.ENVIRONMENT}"
        // Environment-specific Azure credentials
        ARM_CLIENT_ID = credentials("azure-sp-${params.ENVIRONMENT}-client-id")
        ARM_CLIENT_SECRET = credentials("azure-sp-${params.ENVIRONMENT}-client-secret")
        ARM_SUBSCRIPTION_ID = credentials("azure-sp-${params.ENVIRONMENT}-subscription-id")
        ARM_TENANT_ID = credentials("azure-sp-${params.ENVIRONMENT}-tenant-id")
    }
    
    stages {
        stage('Initialize') {
            steps {
                script {
                    echo "[START] Starting deployment for ${env.PROJECT_DISPLAY_NAME}"
                    echo "[INFO] Using Service Principal for environment: ${params.ENVIRONMENT}"
                    
                    // Phase 2: Teams notification
                    // sendTeamsNotification(
                    //     status: 'STARTED',
                    //     projectName: params.PROJECT_NAME,
                    //     environment: params.ENVIRONMENT,
                    //     action: params.ACTION
                    // )
                }
            }
        }
        
        stage('Checkout') {
            steps {
                script {
                    echo "[CHECKOUT] Cloning ${params.PROJECT_NAME} from ${params.GIT_REPO_URL}"
                    echo "[CHECKOUT] Branch: ${params.GIT_BRANCH}"
                    
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: params.GIT_BRANCH]],
                        userRemoteConfigs: [[
                            url: params.GIT_REPO_URL,
                            credentialsId: 'gitlab-credentials'
                        ]]
                    ])
                }
            }
        }
        
        stage('Configure Git') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'gitlab-credentials',
                    usernameVariable: 'GIT_USERNAME',
                    passwordVariable: 'GIT_PASSWORD'
                )]) {
                    sh '''
                        echo "[GIT] Configuring Git credentials"
                        
                        # Evita prompts de interação que travam o job
                        export GIT_TERMINAL_PROMPT=0

                        # Configura diretamente no home do usuário jenkins
                        git config --global user.email "e-vsantiago@tap.pt"
                        git config --global user.name "Vinicius Santiago"
                        git config --global url."https://${GIT_USERNAME}:${GIT_PASSWORD}@gitlab.tap.pt".insteadOf "https://gitlab.tap.pt"
                        
                        # Comando crítico para evitar erro de permissão do Jenkins no Workspace
                        git config --global --add safe.directory '*'
                    '''
                }
            }
        }
        
        stage('Validate') {
            steps {
                sh '''
                    echo "[OK] Validating Terraform code for ${PROJECT_DISPLAY_NAME}"
                    
                    terraform fmt -recursive
                    terraform init -backend=false
                    terraform validate
                    rm -rf .terraform
                '''
            }
        }

        // stage('Security Scan') {
        //     steps {
        //         sh """
        //             echo "[SCAN] Running Trivy security scan using persistent cache for ${PROJECT_DISPLAY_NAME}"
                    
        //             trivy config . \\
        //                 --cache-dir /home/jenkins/.cache/trivy \\
        //                 --skip-dirs .terraform,.git \\
        //                 --format sarif \\
        //                 --output trivy-report-${PROJECT_DISPLAY_NAME}.sarif \\
        //                 --severity MEDIUM,HIGH,CRITICAL || true

        //             trivy convert --format template --template '@contrib/junit.tpl' \\
        //                 trivy-report-${PROJECT_DISPLAY_NAME}.sarif > trivy-report-${PROJECT_DISPLAY_NAME}.xml || true
                    
        //             echo "[OK] Security scan completed"
        //         """
        //     }
        // }
        
        // stage('Cost Estimation') {
        //     steps {
        //         sh """
        //             echo "[COST] Running Infracost for ${PROJECT_DISPLAY_NAME}"
                    
        //             # Generate cost breakdown
        //             infracost breakdown \\
        //                 --path . \\
        //                 --format json \\
        //                 --out-file infracost-${PROJECT_DISPLAY_NAME}.json \\
        //                 --terraform-var environment=${params.ENVIRONMENT} \\
        //                 --terraform-var project_name=${params.PROJECT_NAME} || true
                    
        //             # Generate HTML report
        //             infracost output \\
        //                 --path infracost-${PROJECT_DISPLAY_NAME}.json \\
        //                 --format html \\
        //                 --out-file infracost-${PROJECT_DISPLAY_NAME}.html || true
                    
        //             # Show table summary
        //             echo "[COST] Cost Summary:"
        //             infracost output \\
        //                 --path infracost-${PROJECT_DISPLAY_NAME}.json \\
        //                 --format table || true
                    
        //             echo "[OK] Cost estimation completed"
        //         """
        //     }
        // }

        stage('Terraform Init') {
            steps {
                sh """
                    echo "[INIT] Configuring backend for ${env.PROJECT_DISPLAY_NAME}"
                    
                    cat > backend-config.tfbackend << EOF
resource_group_name  = "azr-prd-iac01-weu-rg"
storage_account_name = "azrprdiac01weust"
container_name       = "terraform-state-${params.ENVIRONMENT}"
key                  = "${params.PROJECT_NAME}/terraform.tfstate"
EOF
                    
                    echo "[INIT] Initializing Terraform with backend config"
                    terraform init -backend-config=backend-config.tfbackend -upgrade
                """
            }
        }
        
        stage('Terraform Plan') {
            steps {
                script {
                    echo "[PLAN] Running Terraform plan for ${env.PROJECT_DISPLAY_NAME}"
                    
                    def planExitCode = sh(
                        script: """
                            terraform plan \\
                                -out=tfplan-${env.PROJECT_DISPLAY_NAME} \\
                                -var-file='environments/${params.ENVIRONMENT}/terraform.tfvars' \\
                                -detailed-exitcode
                        """,
                        returnStatus: true
                    )
                    
                    if (planExitCode == 2) {
                        echo "[WARNING] Changes detected for ${env.PROJECT_DISPLAY_NAME}"
                    } else if (planExitCode == 0) {
                        echo "[OK] No changes required for ${env.PROJECT_DISPLAY_NAME}"
                    } else {
                        error "[ERROR] Terraform plan failed for ${env.PROJECT_DISPLAY_NAME}"
                    }
                    
                    sh "terraform show -json tfplan-${env.PROJECT_DISPLAY_NAME} > tfplan-${env.PROJECT_DISPLAY_NAME}.json"
                }
            }
        }
        
        // stage('Approval') {
        //     when {
        //         expression { 
        //             params.ACTION == 'apply'
        //         }
        //     }
        //     steps {
        //         script {
        //             def approvalMessage = "Approve ${params.ACTION} for ${env.PROJECT_DISPLAY_NAME}?"
        //             def approvers = 'devops-team'
        //             def timeoutHours = 2
                    
        //             // Production requires additional approval
        //             if (params.ENVIRONMENT == 'prd') {
        //                 approvalMessage = "PRODUCTION: Approve ${params.ACTION} for ${env.PROJECT_DISPLAY_NAME}?"
        //                 approvers = 'devops-team,security-team'
        //                 timeoutHours = 4
        //             }
                    
        //             echo "[APPROVAL] Waiting for approval: ${approvalMessage}"
                    
        //             // Phase 2: Add email/Teams notification
        //             // sendTeamsNotification(status: 'PENDING_APPROVAL', ...)
                    
        //             timeout(time: timeoutHours, unit: 'HOURS') {
        //                 input(
        //                     id: 'Approval',
        //                     message: approvalMessage,
        //                     submitter: approvers,
        //                     parameters: [
        //                         text(
        //                             name: 'APPROVAL_COMMENT',
        //                             description: 'Approval comments'
        //                         )
        //                     ]
        //                 )
        //             }
                    
        //             echo "[APPROVAL] Approved by: ${env.BUILD_USER}"
        //         }
        //     }
        // }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
                expression { fileExists("tfplan-${env.PROJECT_DISPLAY_NAME}") }
            }
            steps {
                sh """
                    echo "[APPLY] Applying changes for ${PROJECT_DISPLAY_NAME}"
                    terraform apply tfplan-${PROJECT_DISPLAY_NAME}
                    echo "[SUCCESS] Apply completed for ${PROJECT_DISPLAY_NAME}"
                """
            }
        }

        stage('Save Artifacts') {
            steps {
                script {
                    echo "[ARTIFACTS] Saving pipeline artifacts..."
                    archiveArtifacts artifacts: "**/tfplan-${env.PROJECT_DISPLAY_NAME}.json", allowEmptyArchive: true
                    // junit testResults: "**/trivy-report-${env.PROJECT_DISPLAY_NAME}.xml", allowEmptyResults: true
                    // publishHTML([
                    //     allowMissing: true,
                    //     alwaysLinkToLastBuild: true,
                    //     keepAll: true,
                    //     reportDir: '.',
                    //     reportFiles: "infracost-${env.PROJECT_DISPLAY_NAME}.html",
                    //     reportName: 'Infracost Report'
                    // ])
                    echo "[OK] Artifacts saved (container will be cleaned automatically)"
                }
            }
        }
    }
    
    post {
        success {
            echo "[SUCCESS] ${params.ACTION} completed for ${env.PROJECT_DISPLAY_NAME}"
            echo "[INFO] Build URL: ${env.BUILD_URL}"
        }
        
        failure {
            echo "[FAILURE] ${params.ACTION} failed for ${env.PROJECT_DISPLAY_NAME}"
            echo "[INFO] Build URL: ${env.BUILD_URL}"
        }
    }
}
