// vars/terraformDriftDetection.groovy (Jenkins Shared Library)
// Pipeline agendada para detectar drift em todos os projetos

def call(Map config = [:]) {
    pipeline {
        agent {
            label 'terraform-agent'
        }
        
        triggers {
            cron('H */4 * * *')  // Every 4 hours
        }
        
        stages {
            stage('Detect Drift All Projects') {
                steps {
                    script {
                        def projects = ['project-a', 'project-b', 'project-c']
                        def environments = ['development', 'testing', 'staging', 'production']
                        def driftDetected = []
                        
                        projects.each { project ->
                            environments.each { env ->
                                echo "🔍 Checking drift for ${project}-${env}"
                                
                                try {
                                    checkout([
                                        $class: 'GitSCM',
                                        branches: [[name: 'main']],
                                        userRemoteConfigs: [[
                                            url: "https://gitlab.com/org/terraform-${project}.git"
                                        ]]
                                    ])
                                    
                                    dir("environments/${env}") {
                                        sh 'terraform init'
                                        
                                        def exitCode = sh(
                                            script: 'terraform plan -detailed-exitcode',
                                            returnStatus: true
                                        )
                                        
                                        if (exitCode == 2) {
                                            driftDetected.add("${project}-${env}")
                                            echo "⚠️ DRIFT DETECTED: ${project}-${env}"
                                            
                                            sendTeamsNotification(
                                                status: 'DRIFT_DETECTED',
                                                projectName: project,
                                                environment: env,
                                                buildUrl: env.BUILD_URL
                                            )
                                            
                                            sendDynatraceEvent(
                                                eventType: 'CUSTOM_INFO',
                                                title: 'Terraform Drift Detected',
                                                source: 'Jenkins',
                                                customProperties: [
                                                    project: project,
                                                    environment: env
                                                ]
                                            )
                                        }
                                    }
                                } catch (Exception e) {
                                    echo "❌ Error checking drift for ${project}-${env}: ${e.message}"
                                }
                            }
                        }
                        
                        if (driftDetected.size() > 0) {
                            echo "📊 Drift detected in: ${driftDetected.join(', ')}"
                        } else {
                            echo "✅ No drift detected in any project"
                        }
                    }
                }
            }
        }
    }
}
