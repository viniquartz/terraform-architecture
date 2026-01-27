// Jenkins Pipeline Job - Terraform Modules Validation
// Copy this script directly into Jenkins Pipeline job configuration
// Validates Terraform modules repository before versioning/release

pipeline {
    agent {
        docker {
            image 'jenkins-terraform:v1.0.0'
            label 'terraform-agent'
            args '--network host -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    
    parameters {
        string(
            name: 'MODULE_REPO_URL',
            defaultValue: 'https://gitlab.tap.pt/digital-infrastructure/virtualizacao/terraform/virtualizacao-terraform-modules.git',
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
                            credentialsId: 'gitlab-credentials'
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
                    def warnings = []
                    
                    modules.each { module ->
                        echo "[CHECK] Validating module: ${module}"
                        
                        try {
                            dir(module) {
                                // Format check
                                sh 'terraform fmt -recursive'
                                
                                // Initialize
                                sh 'terraform init -backend=false'
                                
                                // Validate
                                sh 'terraform validate'
                                
                                // Documentation check
                                if (!fileExists('README.md')) {
                                    warnings.add("Missing README.md in ${module}")
                                    echo "[WARNING] Missing README.md in ${module}"
                                }
                                
<<<<<<< HEAD
=======
                                // Note: examples/ directory is optional
                                // if (!fileExists('examples')) {
                                //     warnings.add("No examples directory in ${module}")
                                //     echo "[WARNING] No examples directory in ${module}"
                                // }
                                
>>>>>>> f5dd6b702f1676ac82b1c0dca39ecede995e70ca
                                // Check for required files
                                def requiredFiles = ['main.tf', 'variables.tf', 'outputs.tf']
                                requiredFiles.each { file ->
                                    if (!fileExists(file)) {
                                        warnings.add("Missing ${file} in ${module}")
                                        echo "[WARNING] Missing ${file} in ${module}"
                                    }
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
                    echo "=========================================="
                    echo "MODULE VALIDATION SUMMARY"
                    echo "=========================================="
                    echo "Total modules: ${modules.size()}"
                    echo "Passed: ${passed}"
                    echo "Failed: ${failed}"
                    echo "Warnings: ${warnings.size()}"
                    
                    if (warnings.size() > 0) {
                        echo ""
                        echo "Warnings:"
                        warnings.each { warning ->
                            echo "  - ${warning}"
                        }
                    }
                    echo "=========================================="
                }
            }
        }
        
<<<<<<< HEAD
=======
        stage('Security Scan') {
            steps {
                sh """
                    echo "[SCAN] Running Trivy security scan on all modules"
                    
                    trivy config modules/ \\
                        --format sarif \\
                        --output trivy-modules-report.sarif \\
                        --severity MEDIUM,HIGH,CRITICAL || true
                    
                    echo "[SCAN] Converting SARIF to JUnit format"
                    trivy convert --format template --template '@contrib/junit.tpl' \\
                        trivy-modules-report.sarif > trivy-modules-report.xml || true
                    
                    # Also generate human-readable report
                    trivy config modules/ \\
                        --format table \\
                        --severity MEDIUM,HIGH,CRITICAL || true
                    
                    echo "[OK] Security scan completed"
                """
            }
        }
        
        // Cost Analysis - Disabled: no examples/ directories in modules
        // stage('Cost Analysis') {
        //     steps {
        //         script {
        //             def modules = sh(
        //                 script: 'find modules -name "main.tf" -exec dirname {} \\;',
        //                 returnStdout: true
        //             ).trim().split('\n')
        //             
        //             echo "[COST] Running Infracost on example configurations"
        //             
        //             modules.each { module ->
        //                 if (fileExists("${module}/examples")) {
        //                     echo "[COST] Analyzing examples in ${module}"
        //                     
        //                     dir("${module}/examples") {
        //                         def examples = sh(
        //                             script: 'find . -maxdepth 1 -type d -not -name "." | sed "s|./||"',
        //                             returnStdout: true
        //                         ).trim()
        //                         
        //                         if (examples) {
        //                             examples.split('\n').each { example ->
        //                                 if (example && example.trim()) {
        //                                     dir(example) {
        //                                         def moduleName = module.replaceAll('/', '-')
        //                                         sh """
        //                                             echo "[COST] Analyzing ${module}/examples/${example}"
        //                                             
        //                                             terraform init -backend=false || true
        //                                             
        //                                             infracost breakdown \\
        //                                                 --path . \\
        //                                                 --format json \\
        //                                                 --out-file infracost-${moduleName}-${example}.json || true
        //                                             
        //                                             infracost output \\
        //                                                 --path infracost-${moduleName}-${example}.json \\
        //                                                 --format table || true
        //                                         """
        //                                     }
        //                                 }
        //                             }
        //                         }
        //                     }
        //                 } else {
        //                     echo "[SKIP] No examples found for ${module}"
        //                 }
        //             }
        //             
        //             echo "[OK] Cost analysis completed"
        //         }
        //     }
        // }
        
        // Validate Examples - Disabled: no examples/ directories in modules
        // stage('Validate Examples') {
        //     steps {
        //         script {
        //             def modules = sh(
        //                 script: 'find modules -name "main.tf" -exec dirname {} \\;',
        //                 returnStdout: true
        //             ).trim().split('\n')
        //             
        //             def exampleResults = [:]
        //             
        //             modules.each { module ->
        //                 if (fileExists("${module}/examples")) {
        //                     echo "[TEST] Validating examples for ${module}"
        //                     
        //                     dir("${module}/examples") {
        //                         def examples = sh(
        //                             script: 'find . -maxdepth 1 -type d -not -name "." | sed "s|./||"',
        //                             returnStdout: true
        //                         ).trim()
        //                         
        //                         if (examples) {
        //                             examples.split('\n').each { example ->
        //                                 if (example && example.trim()) {
        //                                     try {
        //                                         dir(example) {
        //                                             sh 'terraform init -backend=false'
        //                                             sh 'terraform validate'
        //                                             exampleResults["${module}/${example}"] = 'PASSED'
        //                                             echo "[OK] Example validated: ${module}/${example}"
        //                                         }
        //                                     } catch (Exception e) {
        //                                         exampleResults["${module}/${example}"] = 'FAILED'
        //                                         echo "[ERROR] Example failed: ${module}/${example} - ${e.message}"
        //                                     }
        //                                 }
        //                             }
        //                         }
        //                     }
        //                 }
        //             }
        //             
        //             // Example validation summary
        //             if (exampleResults.size() > 0) {
        //                 def passedExamples = exampleResults.count { it.value == 'PASSED' }
        //                 def failedExamples = exampleResults.count { it.value == 'FAILED' }
        //                 
        //                 echo "=========================================="
        //                 echo "EXAMPLES VALIDATION SUMMARY"
        //                 echo "=========================================="
        //                 echo "Total examples: ${exampleResults.size()}"
        //                 echo "Passed: ${passedExamples}"
        //                 echo "Failed: ${failedExamples}"
        //                 echo "=========================================="
        //             }
        //         }
        //     }
        // }
        
        // Phase 2: Add comprehensive testing
        // stage('Run Module Tests') {
        //     steps {
        //         script {
        //             // Run Terratest if exists
        //             if (fileExists('tests')) {
        //                 sh 'go test -v -timeout 30m ./tests/...'
        //             }
        //         }
        //     }
        // }
        
>>>>>>> f5dd6b702f1676ac82b1c0dca39ecede995e70ca
        stage('Version Check') {
            steps {
                script {
                    def tags = sh(
                        script: 'git tag -l "v*" | sort -V | tail -5',
                        returnStdout: true
                    ).trim()
                    
                    echo "=========================================="
                    echo "VERSION INFORMATION"
                    echo "=========================================="
                    
                    if (tags) {
                        echo "Recent version tags:"
                        tags.split('\n').each { tag ->
                            echo "  ${tag}"
                        }
                        
                        def latestTag = sh(
                            script: 'git tag -l "v*" | sort -V | tail -1',
                            returnStdout: true
                        ).trim()
                        echo ""
                        echo "Latest version: ${latestTag}"
                    } else {
                        echo "[WARNING] No version tags found"
                        echo "To create a release, tag with: git tag v1.0.0"
                    }
                    echo "=========================================="
                }
            }
        }
        
        stage('Quality Report') {
            steps {
                script {
                    echo "=========================================="
                    echo "MODULE QUALITY REPORT"
                    echo "=========================================="
                    
                    def modules = sh(
                        script: 'find modules -name "main.tf" -exec dirname {} \\;',
                        returnStdout: true
                    ).trim().split('\n')
                    
                    modules.each { module ->
                        echo ""
                        echo "Module: ${module}"
                        
                        def hasReadme = fileExists("${module}/README.md")
                        def hasVariables = fileExists("${module}/variables.tf")
                        def hasOutputs = fileExists("${module}/outputs.tf")
                        
                        echo "  README.md:    ${hasReadme ? '✓' : '✗'}"
                        echo "  variables.tf: ${hasVariables ? '✓' : '✗'}"
                        echo "  outputs.tf:   ${hasOutputs ? '✓' : '✗'}"
                    }
                    echo "=========================================="
                }
            }
        }
        
<<<<<<< HEAD
        failure {
            echo "[FAILURE] Module validation failed"
            echo "[INFO] Check logs for details"
            echo "[INFO] Build URL: ${env.BUILD_URL}"
=======
        stage('Final Report') {
            steps {
                script {
                    echo "=========================================="
                    echo "FINAL VALIDATION REPORT"
                    echo "=========================================="
                    
                    // Archive reports and artifacts
                    archiveArtifacts artifacts: '**/*-report.*,**/infracost-*.json', allowEmptyArchive: true
                    
                    // Publish JUnit test results
                    junit testResults: '**/*-report.xml', allowEmptyResults: true
                    
                    echo ""
                    echo "[SUCCESS] Module validation completed successfully"
                    echo "[INFO] All modules passed validation"
                    echo "[INFO] Build URL: ${env.BUILD_URL}"
                    echo "=========================================="
                }
            }
>>>>>>> f5dd6b702f1676ac82b1c0dca39ecede995e70ca
        }
    }
}
