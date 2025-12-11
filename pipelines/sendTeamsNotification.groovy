// vars/sendTeamsNotification.groovy (Jenkins Shared Library)
// Function to send notifications to Microsoft Teams

def call(Map config = [:]) {
    def webhookUrl = env.TEAMS_WEBHOOK_URL ?: credentials('teams-webhook-url')
    
    def color = [
        'STARTED': '0078D4',
        'SUCCESS': '28A745',
        'FAILURE': 'DC3545',
        'PENDING_APPROVAL': 'FFC107',
        'DRIFT_DETECTED': 'FF9800'
    ][config.status] ?: '6C757D'
    
    def icon = [
        'STARTED': '[START]',
        'SUCCESS': '[SUCCESS]',
        'FAILURE': '[ERROR]',
        'PENDING_APPROVAL': '[WAIT]',
        'DRIFT_DETECTED': '[WARNING]'
    ][config.status] ?: '[INFO]'
    
    def message = [
        '@type': 'MessageCard',
        '@context': 'https://schema.org/extensions',
        'themeColor': color,
        'summary': "${icon} Terraform ${config.action ?: 'Operation'} - ${config.status}",
        'sections': [
            [
                'activityTitle': "${icon} Terraform Deployment",
                'activitySubtitle': "Project: **${config.projectName}** | Environment: **${config.environment}**",
                'facts': [
                    ['name': 'Status', 'value': config.status],
                    ['name': 'Project', 'value': config.projectName],
                    ['name': 'Environment', 'value': config.environment],
                    ['name': 'Action', 'value': config.action ?: 'N/A'],
                    ['name': 'Triggered By', 'value': config.triggeredBy ?: env.BUILD_USER ?: 'System'],
                    ['name': 'Duration', 'value': config.duration ?: 'In progress'],
                    ['name': 'Build Number', 'value': env.BUILD_NUMBER]
                ],
                'markdown': true
            ]
        ],
        'potentialAction': [
            [
                '@type': 'OpenUri',
                'name': 'View Build',
                'targets': [
                    ['os': 'default', 'uri': config.buildUrl ?: env.BUILD_URL]
                ]
            ]
        ]
    ]
    
    if (config.approvalLevel) {
        message.sections[0].facts.add(['name': 'Approval Required', 'value': config.approvalLevel])
    }
    
    if (config.errorLog) {
        message.sections.add([
            'activityTitle': '[ERROR] Error Details',
            'text': "```\n${config.errorLog}\n```",
            'markdown': true
        ])
    }
    
    def payload = groovy.json.JsonOutput.toJson(message)
    
    sh """
        curl -X POST '${webhookUrl}' \\
             -H 'Content-Type: application/json' \\
             -d '${payload}'
    """
}
