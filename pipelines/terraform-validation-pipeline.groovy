// vars/terraformValidation.groovy (Jenkins Shared Library)
// Pipeline for automatic validation on Pull Requests / Merge Requests

def call(Map config = [:]) {
    pipeline {
        agent {
            label 'terraform-agent'
        }
        
        triggers {
            gitlab(
                triggerOnMergeRequest: true,
                branchFilterType: 'All'
            )
        }
        
        environment {
            PROJECT_NAME = sh(
                script: "basename \${GIT_URL} .git | sed 's/terraform-//'",
                returnStdout: true
            ).trim()
        }
        
        stages {
            stage('Validate All Environments') {
                parallel {
                    stage('Production') {
                        steps {
                            validateEnvironment('prd')
                        }
                    }
                    stage('Quality') {
                        steps {
                            validateEnvironment('qlt')
                        }
                    }
                    stage('Testing') {
                        steps {
                            validateEnvironment('tst')
                        }
                    }
                }
            }
        }
        
        post {
            success {
                updateGitlabCommitStatus name: 'terraform-validation', state: 'success'
                addGitLabMRComment comment: "[SUCCESS] Terraform validation passed for all environments"
            }
            failure {
                updateGitlabCommitStatus name: 'terraform-validation', state: 'failed'
                addGitLabMRComment comment: "[ERROR] Terraform validation failed. Check build logs."
            }
        }
    }
}

def validateEnvironment(String env) {
    dir("environments/${env}") {
        sh """
            terraform fmt -check
            terraform init -backend=false
            terraform validate
            tfsec .
        """
    }
}
