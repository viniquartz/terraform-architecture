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
        
        stage('Discover Structure') {
            steps {
                script {
                    echo "[INFO] Discovering repository structure..."
                    sh '''
                        echo "Repository root contents:"
                        ls -la
                        
                        echo ""
                        echo "Searching for Terraform files:"
                        find . -name "*.tf" -type f | head -20
                        
                        echo ""
                        echo "Searching for main.tf files:"
                        find . -name "main.tf" -type f
                    '''
                }
            }
        }
        
        stage('Validate All Modules') {
            steps {
                script {
                    // Find all modules - adjust path based on repository structure
                    def modulesPath = fileExists('modules') ? 'modules' : '.'
                    echo "[INFO] Searching for modules in: ${modulesPath}"
                    
                    def modules = sh(
                        script: "find ${modulesPath} -name 'main.tf' -type f -exec dirname {} \\;",
                        returnStdout: true
                    ).trim().split('\n')
                    
                    if (!modules || modules[0] == '') {
                        error "[ERROR] No Terraform modules found in repository"
                    }
                    
                    echo "[INFO] Found ${modules.size()} module(s)"
                    
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
                    
                    def modulesPath = fileExists('modules') ? 'modules' : '.'
                    def modules = sh(
                        script: "find ${modulesPath} -name 'main.tf' -type f -exec dirname {} \\;",
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
    }
    
    post {
        success {
            echo "[SUCCESS] Module validation passed"
            echo "[INFO] All modules validated successfully"
            echo "[INFO] Build URL: ${env.BUILD_URL}"
        }
        
        failure {
            echo "[FAILURE] Module validation failed"
            echo "[INFO] Check logs for details"
            echo "[INFO] Build URL: ${env.BUILD_URL}"
        }
    }
}
