@description('Specifies the location for resources.')
param location string 

@description('Specifies the app workspace name.')
param app_workspace_name string 

@description('Specifies monitoring workspace id.')
param monitoring_workspace_id string

@description('Specifies dpm workspace id.')
param dpm_workspace_id string

@description('Specifies log analytics reader service principal client id.')
param log_analytics_reader_client_id string

@secure()
@description('Specifies log analytics reader service principal client secret.')
param log_analytics_reader_client_secret string

@description('Specifies app managed environment name.')
param app_environment_name string

@description('Specifies communication service name.')
param communication_service_name string 

@description('Specifies email communication service name.')
param email_service_name string 

@description('Specifies azure alert dispatcher application version.')
param alert_dispather_app_version string

@description('Specifies alert recipient email.')
param alert_recipient_email string

@description('Specifies common tags for all resources')
param common_tags object

var europe_data_location = 'Europe'

resource email_service 'Microsoft.Communication/emailServices@2023-06-01-preview' = {
  name: email_service_name
  location: 'global'
  properties: {
    dataLocation: europe_data_location
  }
  tags: union(common_tags, { context: 'alert' })
}

resource email_domain 'Microsoft.Communication/emailServices/domains@2023-06-01-preview' = {
  parent: email_service
  name: 'AzureManagedDomain'
  location: 'global'
  properties: {
    domainManagement: 'AzureManaged'
    userEngagementTracking: 'Disabled'
  }
  tags: union(common_tags, { context: 'alert' })
}

resource communication_service 'Microsoft.Communication/CommunicationServices@2023-06-01-preview' = {
  name: communication_service_name
  location: 'global'
  tags: union(common_tags, { context: 'alert' })
  properties: {
    dataLocation: europe_data_location
    linkedDomains: [email_domain.id]
  }
}

resource email_sender 'Microsoft.Communication/emailServices/domains/senderusernames@2023-06-01-preview' = {
  name: 'donotreply'
  parent: email_domain
  properties: {
    username: 'DoNotReply'
    displayName: 'DoNotReply'
  }
}

resource app_workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: app_workspace_name
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: union(common_tags, { context: 'alert' })
}

resource managed_environment 'Microsoft.App/managedEnvironments@2023-11-02-preview' = {
  name: app_environment_name
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: app_workspace.properties.customerId
        sharedKey: app_workspace.listKeys().primarySharedKey
        dynamicJsonColumns: false
      }
    }
    zoneRedundant: false
    
  }
  tags: union(common_tags, { context: 'alert' })
}

var alert_dispatcher_app_name = 'alerts-dispatcher'
resource alerts_dispatcher_app 'Microsoft.App/containerapps@2023-11-02-preview' = {
  name: alert_dispatcher_app_name
  location: location
  identity: {
    type: 'None'
  }
  properties: {
    managedEnvironmentId: managed_environment.id
    configuration: {
      secrets: [
        {
          name: 'tenantid'
          value: tenant().tenantId
        }
        {
          name: 'monitoring-workspaceid'
          value: monitoring_workspace_id
        }
        {
          name: 'monitoring-clientid'
          value: log_analytics_reader_client_id
        }
        {
          name: 'monitoring-clientsecrets'
          value: log_analytics_reader_client_secret
        }
        {
          name: 'dpm-workspaceid'
          value: dpm_workspace_id
        }
        {
          name: 'dpm-clientid'
          value: log_analytics_reader_client_id
        }
        {
          name: 'dpm-clientsecret'
          value: log_analytics_reader_client_secret
        }
        {
          name: 'azurecommunicationservice-connectionstring'
          value: communication_service.listKeys().primaryConnectionString
        }
        {
          name: 'azurecommunicationservice-sender'
          value: 'DoNotReply@${email_domain.properties.fromSenderDomain}'
        }        
      ]
      activeRevisionsMode: 'Single'
      dapr: {
        enabled: true
        appId: alert_dispatcher_app_name
        appProtocol: 'http'
        appPort: 80
        logLevel: 'info'
        enableApiLogging: false
      }
    }
    template: {
      containers: [
        {
          image: 'melkio/azure-alert-dispatcher:${alert_dispather_app_version}'
          name: alert_dispatcher_app_name
          env: [
            {
              name: 'AzureCommunicationService__ConnectionString'
              secretRef: 'azurecommunicationservice-connectionstring'
            }
            {
              name: 'AzureCommunicationService__Sender'
              secretRef: 'azurecommunicationservice-sender'
            }
            {
              name: 'AzureCommunicationService__Recipients__0'
              value: alert_recipient_email
            }
            {
              name: 'DataProtectionManager__TenantId'
              secretRef: 'tenantid'
            }
            {
              name: 'DataProtectionManager__WorkspaceId'
              secretRef: 'dpm-workspaceid'
            }
            {
              name: 'DataProtectionManager__ClientId'
              secretRef: 'dpm-clientid'
            }
            {
              name: 'DataProtectionManager__ClientSecret'
              secretRef: 'dpm-clientsecret'
            }
            {
              name: 'HyperV__TenantId'
              secretRef: 'tenantid'
            }
            {
              name: 'HyperV__WorkspaceId'
              secretRef: 'monitoring-workspaceid'
            }
            {
              name: 'HyperV__ClientId'
              secretRef: 'monitoring-clientid'
            }
            {
              name: 'HyperV__ClientSecret'
              secretRef: 'monitoring-clientsecrets'
            }
            {
              name: 'Heartbeat__TenantId'
              secretRef: 'tenantid'
            }
            {
              name: 'Heartbeat__WorkspaceId'
              secretRef: 'monitoring-workspaceid'
            }
            {
              name: 'Heartbeat__ClientId'
              secretRef: 'monitoring-clientid'
            }
            {
              name: 'Heartbeat__ClientSecret'
              secretRef: 'monitoring-clientsecrets'
            }
            {
              name: 'Disk__TenantId'
              secretRef: 'tenantid'
            }
            {
              name: 'Disk__WorkspaceId'
              secretRef: 'monitoring-workspaceid'
            }
            {
              name: 'Disk__ClientId'
              secretRef: 'monitoring-clientid'
            }
            {
              name: 'Disk__ClientSecret'
              secretRef: 'monitoring-clientsecrets'
            }
          ]
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
  tags: union(common_tags, { context: 'alert' })
}

resource heartbeat_cron_scheduler 'Microsoft.App/managedEnvironments/daprComponents@2023-11-02-preview' = {
  parent: managed_environment
  name: 'heartbeat'
  properties: {
    componentType: 'bindings.cron'
    version: 'v1'
    ignoreErrors: false
    secrets: []
    metadata: [
      {
        name: 'schedule'
        value: '0 0/5 * * * *'
      }
      {
        name: 'route'
        value: 'api/alerts/heartbeat'
      }
    ]
    scopes: [
      alert_dispatcher_app_name
    ]
  }
}

resource disk_cron_scheduler 'Microsoft.App/managedEnvironments/daprComponents@2023-11-02-preview' = {
  parent: managed_environment
  name: 'disk'
  properties: {
    componentType: 'bindings.cron'
    version: 'v1'
    ignoreErrors: false
    secrets: []
    metadata: [
      {
        name: 'schedule'
        value: '0 0 8 * * *'
      }
      {
        name: 'route'
        value: 'api/alerts/disk'
      }
    ]
    scopes: [
      alert_dispatcher_app_name
    ]
  }
}

resource dpm_cron_scheduler 'Microsoft.App/managedEnvironments/daprComponents@2023-11-02-preview' = {
  parent: managed_environment
  name: 'dpm'
  properties: {
    componentType: 'bindings.cron'
    version: 'v1'
    ignoreErrors: false
    secrets: []
    metadata: [
      {
        name: 'schedule'
        value: '0 0 8 * * *'
      }
      {
        name: 'route'
        value: 'api/alerts/dpm'
      }
    ]
    scopes: [
      alert_dispatcher_app_name
    ]
  }
}

resource hyperv_cron_scheduler 'Microsoft.App/managedEnvironments/daprComponents@2023-11-02-preview' = {
  parent: managed_environment
  name: 'hyperv'
  properties: {
    componentType: 'bindings.cron'
    version: 'v1'
    ignoreErrors: false
    secrets: []
    metadata: [
      {
        name: 'schedule'
        value: '0 0 * * * *'
      }
      {
        name: 'route'
        value: 'api/alerts/hyperv'
      }
    ]
    scopes: [
      alert_dispatcher_app_name
    ]
  }
}

