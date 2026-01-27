// Jenkins Pipeline Job - Terraform Destroy
// Copy this script directly into Jenkins Pipeline job configuration
// Destroy Terraform resources with approval gates

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
                    echo "[START] Starting DESTROY for ${env.PROJECT_DISPLAY_NAME}"
                    echo "[WARNING] This will DESTROY all resources!"
                    echo "[INFO] Using Service Principal for environment: ${params.ENVIRONMENT}"
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
        
        stage('Terraform Plan Destroy') {
            steps {
                script {
                    echo "[PLAN] Running Terraform plan -destroy for ${env.PROJECT_DISPLAY_NAME}"
                    
                    def planExitCode = sh(
                        script: """
                            terraform plan -destroy \\
                                -out=tfplan-destroy-${env.PROJECT_DISPLAY_NAME} \\
                                -var-file='environments/${params.ENVIRONMENT}/terraform.tfvars' \\
                                -detailed-exitcode
                        """,
                        returnStatus: true
                    )
                    
                    if (planExitCode == 2) {
                        echo "[WARNING] Resources will be DESTROYED for ${env.PROJECT_DISPLAY_NAME}"
                    } else if (planExitCode == 0) {
                        echo "[INFO] No resources to destroy for ${env.PROJECT_DISPLAY_NAME}"
                    } else {
                        error "[ERROR] Terraform plan -destroy failed for ${env.PROJECT_DISPLAY_NAME}"
                    }
                    
                    sh "terraform show -json tfplan-destroy-${env.PROJECT_DISPLAY_NAME} > tfplan-destroy-${env.PROJECT_DISPLAY_NAME}.json"
                }
            }
        }
        
        // stage('Approval') {
        //     steps {
        //         script {
        //             def approvalMessage = "DESTROY: Approve destruction of ${env.PROJECT_DISPLAY_NAME}?"
        //             def approvers = 'devops-team'
        //             def timeoutHours = 4
                    
        //             // Production requires additional approval
        //             if (params.ENVIRONMENT == 'prd') {
        //                 approvalMessage = "PRODUCTION DESTROY: Approve destruction of ${env.PROJECT_DISPLAY_NAME}?"
        //                 approvers = 'devops-team,security-team'
        //                 timeoutHours = 8
        //             }
                    
        //             echo "[APPROVAL] Waiting for approval: ${approvalMessage}"
        //             echo "[WARNING] This will PERMANENTLY DELETE all resources!"
                    
        //             timeout(time: timeoutHours, unit: 'HOURS') {
        //                 input(
        //                     id: 'DestroyApproval',
        //                     message: approvalMessage,
        //                     submitter: approvers,
        //                     parameters: [
        //                         text(
        //                             name: 'APPROVAL_COMMENT',
        //                             description: 'Why are you destroying these resources?'
        //                         ),
        //                         booleanParam(
        //                             name: 'CONFIRM_DESTROY',
        //                             defaultValue: false,
        //                             description: 'I confirm I want to DESTROY all resources'
        //                         )
        //                     ]
        //                 )
        //             }
                    
        //             echo "[APPROVAL] Destroy approved by: ${env.BUILD_USER}"
        //         }
        //     }
        // }
        
        stage('Terraform Destroy') {
            steps {
                sh """
                    echo "[DESTROY] =========================================="
                    echo "[DESTROY] DESTROYING resources for ${PROJECT_DISPLAY_NAME}"
                    echo "[DESTROY] =========================================="
                    
                    terraform destroy \\
                        -var-file='environments/${params.ENVIRONMENT}/terraform.tfvars' \\
                        -auto-approve
                    
                    echo "[SUCCESS] =========================================="
                    echo "[SUCCESS] Destroy completed for ${PROJECT_DISPLAY_NAME}"
                    echo "[SUCCESS] All resources have been removed"
                    echo "[SUCCESS] =========================================="
                """
            }
        }
        
        stage('Save Artifacts') {
            steps {
                script {
                    echo "[ARTIFACTS] Saving pipeline artifacts..."
                    archiveArtifacts artifacts: "**/tfplan-destroy-*.json", allowEmptyArchive: true
                    echo "[OK] Artifacts saved (container will be cleaned automatically)"
                }
            }
        }
    }
    
    post {
        success {
            echo "[SUCCESS] Destroy completed for ${env.PROJECT_DISPLAY_NAME}"
            echo "[INFO] Build URL: ${env.BUILD_URL}"
        }
        
        failure {
            echo "[FAILURE] Destroy failed for ${env.PROJECT_DISPLAY_NAME}"
            echo "[INFO] Build URL: ${env.BUILD_URL}"
        }
    }
}
