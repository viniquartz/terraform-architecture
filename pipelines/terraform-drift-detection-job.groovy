// Jenkins Pipeline Job - Terraform Drift Detection
// Copy this script directly into Jenkins Pipeline job configuration
// Checks for infrastructure drift across all projects and environments

pipeline {
    agent {
        docker {
            image 'jenkins-terraform:v1.0.0'
            label 'terraform-agent'
            args '--network host -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    
    triggers {
        cron('H */4 * * *')  // Every 4 hours - ONLY pipeline with automatic trigger
    }
    
    parameters {
        string(
            name: 'PROJECTS_LIST',
            defaultValue: 'power-bi,digital-cabin',
            description: 'Comma-separated list of project names to check'
        )
        string(
            name: 'GIT_ORG',
            defaultValue: 'org',
            description: 'GitHub/GitLab organization or username'
        )
    }
    
    stages {
        stage('Detect Drift All Projects') {
            steps {
                script {
                    def projects = params.PROJECTS_LIST.split(',').collect { it.trim() }
                    def environments = ['prd', 'qlt', 'tst']
                    def driftDetected = []
                    def driftDetails = [:]
                    
                    projects.each { project ->
                        environments.each { env ->
                            def projectEnv = "${project}-${env}"
                            echo "[CHECK] Checking drift for ${projectEnv}"
                            
                            try {
                                // Checkout project repository
                                checkout([
                                    $class: 'GitSCM',
                                    branches: [[name: 'main']],
                                    userRemoteConfigs: [[
                                        url: "git@github.com:${params.GIT_ORG}/${project}.git",
                                        credentialsId: 'gitlab-credentials'
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
                                                -out=drift-plan-${projectEnv}.tfplan \\
                                                -detailed-exitcode
                                        """,
                                        returnStatus: true
                                    )
                                    
                                    if (exitCode == 2) {
                                        driftDetected.add(projectEnv)
                                        
                                        // Save plan output for review
                                        def planOutput = sh(
                                            script: "terraform show drift-plan-${projectEnv}.tfplan",
                                            returnStdout: true
                                        ).trim()
                                        
                                        driftDetails[projectEnv] = planOutput
                                        
                                        echo "[WARNING] DRIFT DETECTED: ${projectEnv}"
                                        echo "[INFO] Changes detected:"
                                        echo planOutput
                                        
                                        // Save plan as JSON artifact
                                        sh "terraform show -json drift-plan-${projectEnv}.tfplan > drift-plan-${projectEnv}.json"
                                        
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
                                        echo "[OK] No drift detected for ${projectEnv}"
                                    } else {
                                        echo "[ERROR] Plan failed for ${projectEnv}"
                                        driftDetails[projectEnv] = "ERROR: Plan failed"
                                    }
                                }
                            } catch (Exception e) {
                                echo "[ERROR] Error checking drift for ${projectEnv}: ${e.message}"
                                driftDetails[projectEnv] = "ERROR: ${e.message}"
                            }
                        }
                    }
                    
                    // Summary
                    echo "=========================================="
                    echo "DRIFT DETECTION SUMMARY"
                    echo "=========================================="
                    echo "Total projects checked: ${projects.size()}"
                    echo "Total environments checked: ${projects.size() * environments.size()}"
                    echo "Drift detected in: ${driftDetected.size()} project(s)"
                    
                    if (driftDetected.size() > 0) {
                        echo ""
                        echo "Projects with drift:"
                        driftDetected.each { projectEnv ->
                            echo "  - ${projectEnv}"
                        }
                        echo ""
                        echo "[WARNING] Review drift details in build artifacts"
                        currentBuild.result = 'UNSTABLE'
                        currentBuild.description = "Drift detected: ${driftDetected.join(', ')}"
                    } else {
                        echo "[SUCCESS] No drift detected in any project"
                        currentBuild.description = "No drift detected"
                    }
                    echo "=========================================="
                }
            }
        }
    }
    
    post {
        always {
            echo "[INFO] Drift detection completed"
            echo "[INFO] Build URL: ${env.BUILD_URL}"
            
            // Archive drift plans
            archiveArtifacts artifacts: '**/drift-plan-*.json', allowEmptyArchive: true
        }
        
        unstable {
            echo "[ALERT] Drift detected! Review artifacts for details."
        }
    }
}
