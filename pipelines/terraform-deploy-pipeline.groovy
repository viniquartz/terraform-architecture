// vars/terraformDeploy.groovy (Jenkins Shared Library)
// Main pipeline for deploying and destroying Terraform resources
// Manual execution only - no automatic triggers

def call(Map config = [:]) {
    pipeline {
        agent {
            label 'terraform-agent'
        }
        
        parameters {
            string(
                name: 'PROJECT_NAME',
                description: 'Project name (e.g., power-bi, digital-cabin)'
            )
            choice(
                name: 'ENVIRONMENT',
                choices: ['prd', 'qlt', 'tst'],
                description: 'Target environment'
            )
            choice(
                name: 'ACTION',
                choices: ['plan', 'apply', 'destroy'],
                description: 'Terraform action'
            )
            string(
                name: 'GIT_BRANCH',
                defaultValue: 'main',
                description: 'Repository branch'
            )
            string(
                name: 'GIT_REPO_URL',
                description: 'Full Git repository URL'
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
                        echo "[START] Starting deployment for ${PROJECT_DISPLAY_NAME}"
                        echo "[INFO] Using Service Principal for environment: ${params.ENVIRONMENT}"
                        
                        // Phase 2: Teams notification
                        // sendTeamsNotification(
                        //     status: 'STARTED',
                        //     projectName: params.PROJECT_NAME,
                        //     environment: params.ENVIRONMENT,
                        //     action: params.ACTION
                        // )
                        
                        // Phase 2: Dynatrace event
                        // sendDynatraceEvent(
                        //     eventType: 'CUSTOM_DEPLOYMENT',
                        //     title: "Terraform ${params.ACTION} started",
                        //     source: 'Jenkins',
                        //     customProperties: [
                        //         project: params.PROJECT_NAME,
                        //         environment: params.ENVIRONMENT,
                        //         action: params.ACTION
                        //     ]
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
                                credentialsId: 'git-credentials'
                            ]]
                        ])
                    }
                }
            }
            
            stage('Validate') {
                steps {
                    dir("${WORKSPACE_PATH}") {
                        sh """
                            echo "[OK] Validating Terraform code for ${PROJECT_DISPLAY_NAME}"
                            terraform fmt -check -recursive
                            terraform init -backend=false
                            terraform validate
                        """
                    }
                }
            }
            
            stage('Security Scan') {
                steps {
                    sh """
                        echo "[SCAN] Running Trivy security scan for ${PROJECT_DISPLAY_NAME}"
                        
                        trivy config . \\
                            --format sarif \\
                            --output trivy-report-${PROJECT_DISPLAY_NAME}.sarif \\
                            --severity MEDIUM,HIGH,CRITICAL || true
                        
                        trivy convert --format template --template '@contrib/junit.tpl' \\
                            trivy-report-${PROJECT_DISPLAY_NAME}.sarif > trivy-report-${PROJECT_DISPLAY_NAME}.xml || true
                        
                        echo "[OK] Security scan completed"
                    """
                }
            }
            
            stage('Cost Estimation') {
                steps {
                    sh """
                        echo "[COST] Running Infracost for ${PROJECT_DISPLAY_NAME}"
                        
                        # Generate cost breakdown
                        infracost breakdown \\
                            --path . \\
                            --format json \\
                            --out-file infracost-${PROJECT_DISPLAY_NAME}.json \\
                            --terraform-var environment=${params.ENVIRONMENT} \\
                            --terraform-var project_name=${params.PROJECT_NAME} || true
                        
                        # Generate HTML report
                        infracost output \\
                            --path infracost-${PROJECT_DISPLAY_NAME}.json \\
                            --format html \\
                            --out-file infracost-${PROJECT_DISPLAY_NAME}.html || true
                        
                        # Show table summary
                        echo "[COST] Cost Summary:"
                        infracost output \\
                            --path infracost-${PROJECT_DISPLAY_NAME}.json \\
                            --format table || true
                        
                        echo "[OK] Cost estimation completed"
                    """
                }
            }
            
            stage('Terraform Init') {
                steps {
                    sh """
                        echo "[INIT] Configuring backend for ${PROJECT_DISPLAY_NAME}"
                        
                        # Generate dynamic backend configuration
                        cat > backend-config.tfbackend << EOF
resource_group_name  = "rg-terraform-state"
storage_account_name = "stterraformstate"
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
                        echo "[PLAN] Running Terraform plan for ${PROJECT_DISPLAY_NAME}"
                        
                        def planExitCode = sh(
                            script: """
                                terraform plan \\
                                    -out=tfplan-${PROJECT_DISPLAY_NAME} \\
                                    -var='environment=${params.ENVIRONMENT}' \\
                                    -var='project_name=${params.PROJECT_NAME}' \\
                                    -detailed-exitcode
                            """,
                            returnStatus: true
                        )
                        
                        if (planExitCode == 2) {
                            echo "[WARNING] Changes detected for ${PROJECT_DISPLAY_NAME}"
                        } else if (planExitCode == 0) {
                            echo "[OK] No changes required for ${PROJECT_DISPLAY_NAME}"
                        } else {
                            error "[ERROR] Terraform plan failed for ${PROJECT_DISPLAY_NAME}"
                        }
                        
                        sh "terraform show -json tfplan-${PROJECT_DISPLAY_NAME} > tfplan-${PROJECT_DISPLAY_NAME}.json"
                    }
                }
            }
            
            stage('Approval') {
                when {
                    expression { 
                        params.ACTION == 'apply' || params.ACTION == 'destroy'
                    }
                }
                steps {
                    script {
                        def approvalMessage = "Approve ${params.ACTION} for ${PROJECT_DISPLAY_NAME}?"
                        def approvers = 'devops-team'
                        def timeoutHours = 2
                        
                        // Production requires additional approval
                        if (params.ENVIRONMENT == 'prd') {
                            approvalMessage = "PRODUCTION: Approve ${params.ACTION} for ${PROJECT_DISPLAY_NAME}?"
                            approvers = 'devops-team,security-team'
                            timeoutHours = 4
                        }
                        
                        echo "[APPROVAL] Waiting for approval: ${approvalMessage}"
                        
                        // Phase 2: Add email/Teams notification
                        // sendTeamsNotification(status: 'PENDING_APPROVAL', ...)
                        
                        timeout(time: timeoutHours, unit: 'HOURS') {
                            input(
                                id: 'Approval',
                                message: approvalMessage,
                                submitter: approvers,
                                parameters: [
                                    text(
                                        name: 'APPROVAL_COMMENT',
                                        description: 'Approval comments'
                                    )
                                ]
                            )
                        }
                        
                        echo "[APPROVAL] Approved by: ${env.BUILD_USER}"
                    }
                }
            }
            
            stage('Terraform Apply') {
                when {
                    expression { params.ACTION == 'apply' }
                }
                steps {
                    sh """
                        echo "[APPLY] Applying changes for ${PROJECT_DISPLAY_NAME}"
                        terraform apply tfplan-${PROJECT_DISPLAY_NAME}
                        echo "[SUCCESS] Apply completed for ${PROJECT_DISPLAY_NAME}"
                    """
                }
            }
            
            stage('Terraform Destroy') {
                when {
                    expression { params.ACTION == 'destroy' }
                }
                steps {
                    sh """
                        echo "[DESTROY] Destroying resources for ${PROJECT_DISPLAY_NAME}"
                        terraform destroy \\
                            -var='environment=${params.ENVIRONMENT}' \\
                            -var='project_name=${params.PROJECT_NAME}' \\
                            -auto-approve
                        echo "[SUCCESS] Destroy completed for ${PROJECT_DISPLAY_NAME}"
                    """
                }
            }
            
            // Phase 2: Post-deployment validations
            // stage('Post-Deployment Tests') {
            //     when {
            //         expression { params.ACTION == 'apply' }
            //     }
            //     steps {
            //         sh "./scripts/post-deployment-tests.sh ${params.PROJECT_NAME} ${params.ENVIRONMENT}"
            //     }
            // }
        }
        
        post {
            success {
                script {
                    echo "[SUCCESS] ${params.ACTION} completed for ${PROJECT_DISPLAY_NAME}"
                    echo "[INFO] Build URL: ${env.BUILD_URL}"
                    
                    // Phase 2: Teams notification
                    // sendTeamsNotification(
                    //     status: 'SUCCESS',
                    //     projectName: params.PROJECT_NAME,
                    //     environment: params.ENVIRONMENT,
                    //     action: params.ACTION,
                    //     buildUrl: env.BUILD_URL
                    // )
                    
                    // Phase 2: Dynatrace event
                    // sendDynatraceEvent(
                    //     eventType: 'CUSTOM_DEPLOYMENT',
                    //     title: "Terraform ${params.ACTION} completed successfully",
                    //     source: 'Jenkins',
                    //     customProperties: [
                    //         project: params.PROJECT_NAME,
                    //         environment: params.ENVIRONMENT,
                    //         action: params.ACTION,
                    //         status: 'SUCCESS'
                    //     ]
                    // )
                }
            }
            
            failure {
                script {
                    echo "[FAILURE] ${params.ACTION} failed for ${PROJECT_DISPLAY_NAME}"
                    echo "[INFO] Build URL: ${env.BUILD_URL}"
                    
                    // Phase 2: Teams notification
                    // sendTeamsNotification(
                    //     status: 'FAILURE',
                    //     projectName: params.PROJECT_NAME,
                    //     environment: params.ENVIRONMENT,
                    //     action: params.ACTION,
                    //     buildUrl: env.BUILD_URL
                    // )
                    
                    // Phase 2: Dynatrace event
                    // sendDynatraceEvent(
                    //     eventType: 'CUSTOM_DEPLOYMENT',
                    //     title: "Terraform ${params.ACTION} failed",
                    //     source: 'Jenkins',
                    //     customProperties: [
                    //         project: params.PROJECT_NAME,
                    //         environment: params.ENVIRONMENT,
                    //         action: params.ACTION,
                    //         status: 'FAILURE'
                    //     ]
                    // )
                }
            }
            
            always {
                archiveArtifacts artifacts: "**/tfplan-${PROJECT_DISPLAY_NAME}.json", allowEmptyArchive: true
                junit "**/tfsec-report-${PROJECT_DISPLAY_NAME}.xml"
                cleanWs()
            }
        }
    }
}
