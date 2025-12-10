// vars/terraformDeploy.groovy (Jenkins Shared Library)
// Pipeline principal para deploy e destroy de recursos Terraform

def call(Map config = [:]) {
    pipeline {
        agent {
            label 'terraform-agent'
        }
        
        parameters {
            string(
                name: 'PROJECT_NAME',
                description: 'Nome do projeto (ex: project-a, project-b)'
            )
            choice(
                name: 'ENVIRONMENT',
                choices: ['prd', 'qa', 'tst'],
                description: 'Ambiente alvo'
            )
            choice(
                name: 'ACTION',
                choices: ['plan', 'apply', 'destroy'],
                description: 'Ação Terraform'
            )
            string(
                name: 'GIT_BRANCH',
                defaultValue: 'main',
                description: 'Branch do repositório'
            )
        }
        
        environment {
            PROJECT_DISPLAY_NAME = "${params.PROJECT_NAME}-${params.ENVIRONMENT}"
            WORKSPACE_PATH = "environments/${params.ENVIRONMENT}"
            ARM_CLIENT_ID = credentials('azure-client-id')
            ARM_CLIENT_SECRET = credentials('azure-client-secret')
            ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
            ARM_TENANT_ID = credentials('azure-tenant-id')
        }
        
        stages {
            stage('Initialize') {
                steps {
                    script {
                        echo "[START] Starting deployment for ${PROJECT_DISPLAY_NAME}"
                        
                        // Send Teams notification
                        sendTeamsNotification(
                            status: 'STARTED',
                            projectName: params.PROJECT_NAME,
                            environment: params.ENVIRONMENT,
                            action: params.ACTION,
                            triggeredBy: env.BUILD_USER
                        )
                        
                        // Send Dynatrace event
                        sendDynatraceEvent(
                            eventType: 'CUSTOM_DEPLOYMENT',
                            title: "Terraform ${params.ACTION} started",
                            source: 'Jenkins',
                            customProperties: [
                                project: params.PROJECT_NAME,
                                environment: params.ENVIRONMENT,
                                action: params.ACTION
                            ]
                        )
                    }
                }
            }
            
            stage('Checkout') {
                steps {
                    script {
                        echo "[CHECKOUT] Checking out ${params.PROJECT_NAME} from branch ${params.GIT_BRANCH}"
                        
                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: params.GIT_BRANCH]],
                            userRemoteConfigs: [[
                                url: "https://gitlab.com/org/terraform-${params.PROJECT_NAME}.git",
                                credentialsId: 'gitlab-credentials'
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
                parallel {
                    stage('TFSec') {
                        steps {
                            dir("${WORKSPACE_PATH}") {
                                sh """
                                    tfsec . --format junit --out tfsec-report-${PROJECT_DISPLAY_NAME}.xml
                                """
                            }
                        }
                    }
                    stage('Checkov') {
                        steps {
                            dir("${WORKSPACE_PATH}") {
                                sh """
                                    checkov -d . --framework terraform \\
                                        --output junitxml --output-file checkov-report-${PROJECT_DISPLAY_NAME}.xml
                                """
                            }
                        }
                    }
                }
            }
            
            stage('Terraform Init') {
                steps {
                    dir("${WORKSPACE_PATH}") {
                        sh """
                            echo "[INIT] Initializing Terraform for ${PROJECT_DISPLAY_NAME}"
                            terraform init -upgrade
                        """
                    }
                }
            }
            
            stage('Terraform Plan') {
                steps {
                    dir("${WORKSPACE_PATH}") {
                        script {
                            def planExitCode = sh(
                                script: """
                                    terraform plan \\
                                        -out=tfplan-${PROJECT_DISPLAY_NAME} \\
                                        -var-file=terraform.tfvars \\
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
            }
            
            stage('Approval - DevOps Team') {
                when {
                    expression { 
                        params.ACTION == 'apply' || params.ACTION == 'destroy'
                    }
                }
                steps {
                    script {
                        sendTeamsNotification(
                            status: 'PENDING_APPROVAL',
                            projectName: params.PROJECT_NAME,
                            environment: params.ENVIRONMENT,
                            action: params.ACTION,
                            approvalLevel: 'DevOps Team'
                        )
                        
                        timeout(time: 2, unit: 'HOURS') {
                            input(
                                id: 'DevOpsApproval',
                                message: "Approve ${params.ACTION} for ${PROJECT_DISPLAY_NAME}?",
                                submitter: 'devops-team',
                                parameters: [
                                    text(
                                        name: 'APPROVAL_COMMENT',
                                        description: 'Comments for this approval'
                                    )
                                ]
                            )
                        }
                    }
                }
            }
            
            stage('Approval - Security Team') {
                when {
                    expression { 
                        (params.ACTION == 'apply' || params.ACTION == 'destroy') && 
                        params.ENVIRONMENT == 'production'
                    }
                }
                steps {
                    script {
                        sendTeamsNotification(
                            status: 'PENDING_APPROVAL',
                            projectName: params.PROJECT_NAME,
                            environment: params.ENVIRONMENT,
                            action: params.ACTION,
                            approvalLevel: 'Security Team (Production)'
                        )
                        
                        timeout(time: 4, unit: 'HOURS') {
                            input(
                                id: 'SecurityApproval',
                                message: "Security Team: Approve ${params.ACTION} for ${PROJECT_DISPLAY_NAME} (PRODUCTION)?",
                                submitter: 'security-team',
                                parameters: [
                                    text(
                                        name: 'SECURITY_APPROVAL_COMMENT',
                                        description: 'Security review comments'
                                    )
                                ]
                            )
                        }
                    }
                }
            }
            
            stage('Terraform Apply') {
                when {
                    expression { params.ACTION == 'apply' }
                }
                steps {
                    dir("${WORKSPACE_PATH}") {
                        sh """
                            echo "[START] Applying changes for ${PROJECT_DISPLAY_NAME}"
                            terraform apply tfplan-${PROJECT_DISPLAY_NAME}
                        """
                    }
                }
            }
            
            stage('Terraform Destroy') {
                when {
                    expression { params.ACTION == 'destroy' }
                }
                steps {
                    dir("${WORKSPACE_PATH}") {
                        sh """
                            echo "[DESTROY] Destroying resources for ${PROJECT_DISPLAY_NAME}"
                            terraform destroy -var-file=terraform.tfvars -auto-approve
                        """
                    }
                }
            }
            
            stage('Post-Deployment Tests') {
                when {
                    expression { params.ACTION == 'apply' }
                }
                steps {
                    sh """
                        echo "[TEST] Running post-deployment tests for ${PROJECT_DISPLAY_NAME}"
                        ./scripts/post-deployment-tests.sh ${params.PROJECT_NAME} ${params.ENVIRONMENT}
                    """
                }
            }
        }
        
        post {
            success {
                script {
                    sendTeamsNotification(
                        status: 'SUCCESS',
                        projectName: params.PROJECT_NAME,
                        environment: params.ENVIRONMENT,
                        action: params.ACTION,
                        buildUrl: env.BUILD_URL,
                        duration: currentBuild.durationString
                    )
                    
                    sendDynatraceEvent(
                        eventType: 'CUSTOM_DEPLOYMENT',
                        title: "Terraform ${params.ACTION} completed successfully",
                        source: 'Jenkins',
                        customProperties: [
                            project: params.PROJECT_NAME,
                            environment: params.ENVIRONMENT,
                            action: params.ACTION,
                            duration: currentBuild.duration,
                            status: 'SUCCESS'
                        ]
                    )
                }
            }
            
            failure {
                script {
                    sendTeamsNotification(
                        status: 'FAILURE',
                        projectName: params.PROJECT_NAME,
                        environment: params.ENVIRONMENT,
                        action: params.ACTION,
                        buildUrl: env.BUILD_URL,
                        errorLog: currentBuild.rawBuild.getLog(50).join('\n')
                    )
                    
                    sendDynatraceEvent(
                        eventType: 'CUSTOM_DEPLOYMENT',
                        title: "Terraform ${params.ACTION} failed",
                        source: 'Jenkins',
                        customProperties: [
                            project: params.PROJECT_NAME,
                            environment: params.ENVIRONMENT,
                            action: params.ACTION,
                            status: 'FAILURE'
                        ]
                    )
                }
            }
            
            always {
                archiveArtifacts artifacts: "**/tfplan-${PROJECT_DISPLAY_NAME}.json", allowEmptyArchive: true
                junit "**/tfsec-report-${PROJECT_DISPLAY_NAME}.xml, **/checkov-report-${PROJECT_DISPLAY_NAME}.xml"
                cleanWs()
            }
        }
    }
}
