// vars/sendDynatraceEvent.groovy (Jenkins Shared Library)
// Função para enviar eventos e métricas ao Dynatrace

def call(Map config = [:]) {
    def dynatraceUrl = env.DYNATRACE_URL ?: credentials('dynatrace-url')
    def dynatraceToken = credentials('dynatrace-api-token')
    
    def event = [
        eventType: config.eventType ?: 'CUSTOM_DEPLOYMENT',
        title: config.title,
        source: config.source ?: 'Jenkins',
        description: config.description ?: '',
        customProperties: config.customProperties ?: [:],
        attachRules: [
            tagRule: [[
                meTypes: ['SERVICE'],
                tags: [[
                    context: 'CONTEXTLESS',
                    key: 'project',
                    value: config.customProperties.project
                ]]
            ]]
        ]
    ]
    
    def payload = groovy.json.JsonOutput.toJson(event)
    
    sh """
        curl -X POST '${dynatraceUrl}/api/v1/events' \\
             -H 'Authorization: Api-Token ${dynatraceToken}' \\
             -H 'Content-Type: application/json' \\
             -d '${payload}'
    """
    
    // Send build metrics
    if (config.customProperties.duration) {
        def metrics = [
            [
                name: 'terraform.pipeline.duration',
                value: config.customProperties.duration,
                dimensions: [
                    project: config.customProperties.project,
                    environment: config.customProperties.environment,
                    action: config.customProperties.action
                ]
            ],
            [
                name: 'terraform.pipeline.status',
                value: config.customProperties.status == 'SUCCESS' ? 1 : 0,
                dimensions: [
                    project: config.customProperties.project,
                    environment: config.customProperties.environment
                ]
            ]
        ]
        
        def metricsPayload = groovy.json.JsonOutput.toJson(metrics)
        
        sh """
            curl -X POST '${dynatraceUrl}/api/v2/metrics/ingest' \\
                 -H 'Authorization: Api-Token ${dynatraceToken}' \\
                 -H 'Content-Type: application/json' \\
                 -d '${metricsPayload}'
        """
    }
}
