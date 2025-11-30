// vars/terraformModulesValidation.groovy (Jenkins Shared Library)
// Pipeline para validação e testes dos módulos Terraform no monorepo

def call(Map config = [:]) {
    pipeline {
        agent {
            label 'terraform-agent'
        }
        
        triggers {
            gitlab(
                triggerOnPush: true,
                triggerOnMergeRequest: true,
                branchFilterType: 'All'
            )
        }
        
        environment {
            MODULE_REPO = 'terraform-azure-modules'
        }
        
        stages {
            stage('Checkout') {
                steps {
                    checkout scm
                }
            }
            
            stage('Detect Changed Modules') {
                steps {
                    script {
                        // Get list of changed modules
                        def changedModules = sh(
                            script: """
                                git diff --name-only HEAD~1 HEAD | grep '^modules/' | cut -d/ -f1-3 | sort -u
                            """,
                            returnStdout: true
                        ).trim().split('\n')
                        
                        env.CHANGED_MODULES = changedModules.join(',')
                        echo "[CHECKOUT] Changed modules: ${env.CHANGED_MODULES}"
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
                                        error "Missing README.md in ${module}"
                                    }
                                    
                                    if (!fileExists('examples')) {
                                        echo "[WARNING] Warning: No examples directory in ${module}"
                                    }
                                    
                                    validationResults[module] = 'PASSED'
                                    echo "[SUCCESS] ${module} validation passed"
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
                        echo "[METRICS] Validation Summary: ${passed} passed, ${failed} failed"
                    }
                }
            }
            
            stage('Security Scan Modules') {
                parallel {
                    stage('TFSec All Modules') {
                        steps {
                            sh """
                                tfsec modules/ \\
                                    --format junit \\
                                    --out tfsec-modules-report.xml \\
                                    --minimum-severity MEDIUM
                            """
                        }
                    }
                    stage('Checkov All Modules') {
                        steps {
                            sh """
                                checkov -d modules/ \\
                                    --framework terraform \\
                                    --output junitxml \\
                                    --output-file checkov-modules-report.xml
                            """
                        }
                    }
                }
            }
            
            stage('Run Module Tests') {
                when {
                    expression { env.CHANGED_MODULES != '' }
                }
                steps {
                    script {
                        def changedModules = env.CHANGED_MODULES.split(',')
                        
                        changedModules.each { module ->
                            if (fileExists("${module}/tests")) {
                                echo "[TEST] Running tests for ${module}"
                                dir("${module}/tests") {
                                    // Run Terratest if exists
                                    if (fileExists('go.mod')) {
                                        sh 'go test -v -timeout 30m'
                                    }
                                    
                                    // Run example validation
                                    dir('../examples') {
                                        def examples = sh(
                                            script: 'find . -maxdepth 1 -type d | tail -n +2',
                                            returnStdout: true
                                        ).trim().split('\n')
                                        
                                        examples.each { example ->
                                            dir(example) {
                                                sh 'terraform init'
                                                sh 'terraform validate'
                                                sh 'terraform plan'
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            stage('Generate Module Catalog') {
                steps {
                    sh """
                        echo '# Terraform Azure Modules Catalog' > MODULE_CATALOG.md
                        echo '' >> MODULE_CATALOG.md
                        echo 'Auto-generated on: \$(date)' >> MODULE_CATALOG.md
                        echo '' >> MODULE_CATALOG.md
                        
                        find modules -name "main.tf" -exec dirname {} \\; | sort | while read module; do
                            echo "## \${module}" >> MODULE_CATALOG.md
                            if [ -f "\${module}/README.md" ]; then
                                head -n 5 "\${module}/README.md" >> MODULE_CATALOG.md
                            fi
                            echo '' >> MODULE_CATALOG.md
                        done
                    """
                    archiveArtifacts artifacts: 'MODULE_CATALOG.md'
                }
            }
            
            stage('Version Check') {
                when {
                    branch 'main'
                }
                steps {
                    script {
                        // Check if version tags are properly formatted
                        def tags = sh(
                            script: 'git tag -l',
                            returnStdout: true
                        ).trim()
                        
                        if (tags) {
                            echo "[INFO] Existing version tags:"
                            echo tags
                        } else {
                            echo "[WARNING] No version tags found. Consider tagging releases."
                        }
                    }
                }
            }
        }
        
        post {
            success {
                script {
                    updateGitlabCommitStatus name: 'modules-validation', state: 'success'
                    addGitLabMRComment comment: """
                        [SUCCESS] **Module Validation Passed**
                        
                        All modules validated successfully:
                        - Format check: [SUCCESS]
                        - Terraform validate: [SUCCESS]
                        - Security scan: [SUCCESS]
                        - Tests: [SUCCESS]
                        
                        [View detailed results](${env.BUILD_URL})
                    """
                    
                    sendTeamsNotification(
                        status: 'SUCCESS',
                        projectName: 'terraform-azure-modules',
                        environment: 'validation',
                        action: 'validate',
                        buildUrl: env.BUILD_URL
                    )
                    
                    sendDynatraceEvent(
                        eventType: 'CUSTOM_DEPLOYMENT',
                        title: 'Module validation successful',
                        source: 'Jenkins',
                        customProperties: [
                            project: 'terraform-azure-modules',
                            status: 'SUCCESS'
                        ]
                    )
                }
            }
            
            failure {
                script {
                    updateGitlabCommitStatus name: 'modules-validation', state: 'failed'
                    addGitLabMRComment comment: """
                        [ERROR] **Module Validation Failed**
                        
                        Some modules failed validation. Please check:
                        - Terraform formatting
                        - Syntax errors
                        - Security issues
                        - Missing documentation
                        
                        [View detailed logs](${env.BUILD_URL})
                    """
                    
                    sendTeamsNotification(
                        status: 'FAILURE',
                        projectName: 'terraform-azure-modules',
                        environment: 'validation',
                        action: 'validate',
                        buildUrl: env.BUILD_URL
                    )
                }
            }
            
            always {
                junit '**/tfsec-modules-report.xml, **/checkov-modules-report.xml'
                archiveArtifacts artifacts: '**/*-report.xml', allowEmptyArchive: true
                cleanWs()
            }
        }
    }
}
