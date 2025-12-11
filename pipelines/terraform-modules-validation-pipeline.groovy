// vars/terraformModulesValidation.groovy (Jenkins Shared Library)
// Pipeline for validation and testing of Terraform modules repository
// Manual execution only - no automatic triggers

def call(Map config = [:]) {
    pipeline {
        agent {
            label 'terraform-agent'
        }
        
        parameters {
            string(
                name: 'MODULE_REPO_URL',
                description: 'Terraform modules repository URL'
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
                        echo "[CHECKOUT] Cloning modules repository: ${params.MODULE_REPO_URL}"
                        echo "[CHECKOUT] Branch: ${params.GIT_BRANCH}"
                        
                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: params.GIT_BRANCH]],
                            userRemoteConfigs: [[
                                url: params.MODULE_REPO_URL,
                                credentialsId: 'git-credentials'
                            ]]
                        ])
                    }
                }
            }
            
            stage('Validate All Modules') {
                steps {
                    script {
                        def modules = sh(
                            script: 'find modules -name "main.tf" -exec dirname {} \\;',
                            returnStdout: true
                        ).trim().split('\n')
                        
                        def validationResults = [:]
                        
                        modules.each { module ->
                            echo "[CHECK] Validating module: ${module}"
                            
                            try {
                                dir(module) {
                                    // Format check
                                    sh 'terraform fmt -check -recursive'
                                    
                                    // Initialize
                                    sh 'terraform init -backend=false'
                                    
                                    // Validate
                                    sh 'terraform validate'
                                    
                                    // Documentation check
                                    if (!fileExists('README.md')) {
                                        echo "[WARNING] Missing README.md in ${module}"
                                    }
                                    
                                    if (!fileExists('examples')) {
                                        echo "[WARNING] No examples directory in ${module}"
                                    }
                                    
                                    validationResults[module] = 'PASSED'
                                    echo "[OK] ${module} validation passed"
                                }
                            } catch (Exception e) {
                                validationResults[module] = 'FAILED'
                                echo "[ERROR] ${module} validation failed: ${e.message}"
                                currentBuild.result = 'FAILURE'
                            }
                        }
                        
                        // Summary
                        def passed = validationResults.count { it.value == 'PASSED' }
                        def failed = validationResults.count { it.value == 'FAILED' }
                        echo "[SUMMARY] Validation: ${passed} passed, ${failed} failed"
                    }
                }
            }
            
            stage('Security Scan') {
                steps {
                    sh """
                        echo "[SCAN] Running TFSec security scan on all modules"
                        tfsec modules/ \\
                            --format junit \\
                            --out tfsec-modules-report.xml \\
                            --minimum-severity MEDIUM || true
                        echo "[OK] Security scan completed"
                    """
                    // Phase 2: Add Checkov if needed
                    // sh "checkov -d modules/ --framework terraform"
                }
            }
            
            stage('Validate Examples') {
                steps {
                    script {
                        def modules = sh(
                            script: 'find modules -name "main.tf" -exec dirname {} \\;',
                            returnStdout: true
                        ).trim().split('\n')
                        
                        modules.each { module ->
                            if (fileExists("${module}/examples")) {
                                echo "[TEST] Validating examples for ${module}"
                                
                                dir("${module}/examples") {
                                    def examples = sh(
                                        script: 'find . -maxdepth 1 -type d | tail -n +2',
                                        returnStdout: true
                                    ).trim().split('\n')
                                    
                                    examples.each { example ->
                                        dir(example) {
                                            sh 'terraform init -backend=false'
                                            sh 'terraform validate'
                                            echo "[OK] Example validated: ${example}"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Phase 2: Add comprehensive testing
            // stage('Run Module Tests') {
            //     steps {
            //         script {
            //             // Run Terratest if exists
            //             sh 'go test -v -timeout 30m ./tests/...'
            //         }
            //     }
            // }
            
            stage('Version Check') {
                steps {
                    script {
                        def tags = sh(
                            script: 'git tag -l "v*" | sort -V | tail -5',
                            returnStdout: true
                        ).trim()
                        
                        if (tags) {
                            echo "[INFO] Recent version tags:"
                            echo tags
                        } else {
                            echo "[WARNING] No version tags found. Tag releases with: git tag v1.0.0"
                        }
                    }
                }
            }
        }
        
        post {
            success {
                script {
                    echo "[SUCCESS] Module validation passed"
                    echo "[INFO] All modules validated successfully"
                    echo "[INFO] Build URL: ${env.BUILD_URL}"
                    
                    // Phase 2: GitLab MR comments
                    // updateGitlabCommitStatus name: 'modules-validation', state: 'success'
                    // addGitLabMRComment comment: "[SUCCESS] Module validation passed"
                    
                    // Phase 2: Teams notification
                    // sendTeamsNotification(
                    //     status: 'SUCCESS',
                    //     projectName: 'terraform-azure-modules',
                    //     action: 'validate',
                    //     buildUrl: env.BUILD_URL
                    // )
                    
                    // Phase 2: Dynatrace event
                    // sendDynatraceEvent(
                    //     eventType: 'CUSTOM_DEPLOYMENT',
                    //     title: 'Module validation successful',
                    //     source: 'Jenkins',
                    //     customProperties: [project: 'terraform-azure-modules', status: 'SUCCESS']
                    // )
                }
            }
            
            failure {
                script {
                    echo "[FAILURE] Module validation failed"
                    echo "[INFO] Check logs for details"
                    echo "[INFO] Build URL: ${env.BUILD_URL}"
                    
                    // Phase 2: GitLab MR comments
                    // updateGitlabCommitStatus name: 'modules-validation', state: 'failed'
                    // addGitLabMRComment comment: "[ERROR] Module validation failed. Check logs."
                    
                    // Phase 2: Teams notification
                    // sendTeamsNotification(status: 'FAILURE', projectName: 'terraform-azure-modules')
                }
            }
            
            always {
                junit "**/tfsec-modules-report.xml"
                archiveArtifacts artifacts: '**/*-report.xml', allowEmptyArchive: true
                cleanWs()
            }
        }
    }
}
