// vars/terraformDriftDetection.groovy (Jenkins Shared Library)
// Scheduled pipeline to detect drift in all projects
// Runs automatically every 4 hours

def call(Map config = [:]) {
    pipeline {
        agent {
            label 'terraform-agent'
        }
        
        triggers {
            cron('H */4 * * *')  // Every 4 hours - only pipeline with automatic trigger
        }
        
        parameters {
            string(
                name: 'PROJECTS_LIST',
                defaultValue: 'power-bi,digital-cabin',
                description: 'Comma-separated list of project names to check'
            )
        }
        
        stages {
            stage('Detect Drift All Projects') {
                steps {
                    script {
                        def projects = params.PROJECTS_LIST.split(',')
                        def environments = ['prd', 'qlt', 'tst']
                        def driftDetected = []
                        
                        projects.each { project ->
                            environments.each { env ->
                                echo "[CHECK] Checking drift for ${project}-${env}"
                                
                                try {
                                    // Checkout project repository
                                    checkout([
                                        $class: 'GitSCM',
                                        branches: [[name: 'main']],
                                        userRemoteConfigs: [[
                                            url: "git@github.com:org/${project}.git",
                                            credentialsId: 'git-credentials'
                                        ]]
                                    ])
                                    
                                    // Set environment-specific credentials
                                    withCredentials([
                                        string(credentialsId: "azure-sp-${env}-client-id", variable: 'ARM_CLIENT_ID'),
                                        string(credentialsId: "azure-sp-${env}-client-secret", variable: 'ARM_CLIENT_SECRET'),
                                        string(credentialsId: "azure-sp-${env}-subscription-id", variable: 'ARM_SUBSCRIPTION_ID'),
                                        string(credentialsId: "azure-sp-${env}-tenant-id", variable: 'ARM_TENANT_ID')
                                    ]) {
                                        // Generate backend configuration
                                        sh """
                                            cat > backend-config.tfbackend << EOF
resource_group_name  = "rg-terraform-state"
storage_account_name = "stterraformstate"
container_name       = "terraform-state-${env}"
key                  = "${project}/terraform.tfstate"
EOF
                                        """
                                        
                                        // Initialize and check for drift
                                        sh 'terraform init -backend-config=backend-config.tfbackend'
                                        
                                        def exitCode = sh(
                                            script: """
                                                terraform plan \\
                                                    -var-file='environments/${env}/terraform.tfvars' \\
                                                    -detailed-exitcode
                                            """,
                                            returnStatus: true
                                        )
                                        
                                        if (exitCode == 2) {
                                            driftDetected.add("${project}-${env}")
                                            echo "[WARNING] DRIFT DETECTED: ${project}-${env}"
                                            
                                            // Phase 2: Notifications
                                            // sendTeamsNotification(
                                            //     status: 'DRIFT_DETECTED',
                                            //     projectName: project,
                                            //     environment: env,
                                            //     buildUrl: env.BUILD_URL
                                            // )
                                            
                                            // sendDynatraceEvent(
                                            //     eventType: 'CUSTOM_INFO',
                                            //     title: 'Terraform Drift Detected',
                                            //     source: 'Jenkins',
                                            //     customProperties: [
                                            //         project: project,
                                            //         environment: env
                                            //     ]
                                            // )
                                        } else if (exitCode == 0) {
                                            echo "[OK] No drift detected for ${project}-${env}"
                                        } else {
                                            echo "[ERROR] Plan failed for ${project}-${env}"
                                        }
                                    }
                                } catch (Exception e) {
                                    echo "[ERROR] Error checking drift for ${project}-${env}: ${e.message}"
                                }
                                
                                // Clean workspace for next project
                                cleanWs()
                            }
                        }
                        
                        // Summary
                        if (driftDetected.size() > 0) {
                            echo "[SUMMARY] Drift detected in ${driftDetected.size()} project(s): ${driftDetected.join(', ')}"
                            currentBuild.result = 'UNSTABLE'
                        } else {
                            echo "[SUCCESS] No drift detected in any project"
                        }
                    }
                }
            }
        }
        
        post {
            always {
                echo "[INFO] Drift detection completed"
                echo "[INFO] Build URL: ${env.BUILD_URL}"
            }
        }
    }
}
