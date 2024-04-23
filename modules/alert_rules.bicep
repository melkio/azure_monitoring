@description('Specifies the location for resources.')
param location string 

@description('Specifies event hub namespace name for alerts')
param alert_event_hub_namespace_name string

@description('Specifies the workspace id for heartbeat, disks space and hyperv alerts')
param monitoring_workspace_id string

@description('Specifies the workspace id for dpm alerts')
param dpm_workspace_id string

@description('Specifies common tags for all resources')
param common_tags object

resource alert_event_hub_namespace 'Microsoft.EventHub/namespaces@2021-06-01-preview' = {
  name: alert_event_hub_namespace_name
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 1
  }
  properties: {
    zoneRedundant: false
  }
  tags: common_tags
}

resource alert_event_hub 'Microsoft.EventHub/namespaces/eventhubs@2021-06-01-preview' = {
  parent: alert_event_hub_namespace
  name: 'alert_event_hub'
  properties: {
    messageRetentionInDays: 1
    partitionCount: 1
  }
}

var action_groups_name = 'support'
resource support_action_group 'microsoft.insights/actionGroups@2023-01-01' = {
  name: action_groups_name
  location: 'global'
  properties: {
    enabled: true
    groupShortName: action_groups_name
    eventHubReceivers: [{
      name: 'alert_event_hub_dispatcher'
      eventHubNameSpace: alert_event_hub_namespace.name
      eventHubName: alert_event_hub.name
      subscriptionId: subscription().subscriptionId
    }]
  }
  tags: common_tags
}

var heartbeat_alert_name = 'missing_heartbeat_alert'
resource heartbeat_alert 'microsoft.insights/scheduledqueryrules@2023-03-15-preview' = {
  name: heartbeat_alert_name
  location: location
  properties: {
    enabled: true
    displayName: heartbeat_alert_name
    description: 'Alert (critical) if at least a heartbeat is missing for more than 5 minutes'
    severity: 0
    evaluationFrequency: 'PT5M'
    scopes: [monitoring_workspace_id]
    targetResourceTypes: ['Microsoft.OperationalInsights/workspaces']
    windowSize: 'P2D'
    overrideQueryTimeRange: 'P2D'
    criteria: {
      allOf: [
        {
          query: '''Heartbeat
          | summarize arg_max(TimeGenerated, *) by Computer
          | where now() - TimeGenerated > 5m
          | project TimeGenerated, Computer'''
          timeAggregation: 'Count'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    actions: {
      actionGroups: [support_action_group.id]
    }
  }
  tags: common_tags
}

var dpm_alerts_name = 'dpm_unresolved_alerts'
resource dpm_alerts 'microsoft.insights/scheduledqueryrules@2023-03-15-preview' = {
  name: dpm_alerts_name
  location: location
  properties: {
    enabled: true
    displayName: dpm_alerts_name
    description: 'Alert (critical) if at least a dpm alert is unresolved'
    severity: 0
    evaluationFrequency: 'P1D'
    scopes: [dpm_workspace_id]
    targetResourceTypes: ['Microsoft.OperationalInsights/workspaces']
    windowSize: 'P2D'
    criteria: {
      allOf: [
        {
          query: '''AddonAzureBackupAlerts
          | summarize arg_max(TimeGenerated, *) by BackupItemUniqueId
          | where AlertStatus != "Resolved"
          | where BackupItemUniqueId != ""
          | project
              A_BackupItemUniqueId=BackupItemUniqueId,
              A_AlertSeverity=AlertSeverity,
              A_AlertType=AlertType,
              A_AlertStatus=AlertStatus
          | join kind=inner (CoreAzureBackup
                | where OperationName == "BackupItem"
              | summarize arg_max(TimeGenerated, *) by BackupItemUniqueId
              | project
                  BI_BackupItemUniqueId=BackupItemUniqueId,
                  BI_BackupItemFriendlyName=BackupItemFriendlyName
              | join kind=inner (CoreAzureBackup
                    | where OperationName == "BackupItemAssociation"
                  | summarize arg_max(TimeGenerated, *) by BackupItemUniqueId
                  | project
                      BIA_BackupItemUniqueId=BackupItemUniqueId,
                      BIA_ProtectedContainerUniqueId=ProtectedContainerUniqueId
                  | join kind=inner (CoreAzureBackup
                        | where OperationName == "ProtectedContainer"
                      | summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId 
                      | project
                          PC_ProtectedContainerUniqueId=ProtectedContainerUniqueId,
                          PC_ProtectedContainerFriendlyName=ProtectedContainerFriendlyName)
                      on $left.BIA_ProtectedContainerUniqueId == $right.PC_ProtectedContainerUniqueId
                  | project BIA_BackupItemUniqueId, PC_ProtectedContainerFriendlyName)
                  on $left.BI_BackupItemUniqueId == $right.BIA_BackupItemUniqueId
              | project
                  T_BackupItemUniqueId=BI_BackupItemUniqueId,
                  T_ProtectedContainerFriendlyName=PC_ProtectedContainerFriendlyName,
                  T_BackupItemFriendlyName=BI_BackupItemFriendlyName)
              on $left.A_BackupItemUniqueId == $right.T_BackupItemUniqueId
          | project
              ProtectedContainerFriendlyName=T_ProtectedContainerFriendlyName,
              BackupItemFriendlyName=T_BackupItemFriendlyName,
              AlertType=A_AlertType,
              AlertSeverity=A_AlertSeverity
          | order by AlertSeverity asc, ProtectedContainerFriendlyName asc '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    actions: {
      actionGroups: [support_action_group.id]
    }
  }
  tags: common_tags
}

var hyperv_alerts_name = 'hyperv_winevents_alerts'
resource hyperv_alerts 'microsoft.insights/scheduledqueryrules@2023-03-15-preview' = {
  name: hyperv_alerts_name
  location: location
  properties: {
    displayName: hyperv_alerts_name
    description: 'Alert (critical) if at least a windows event exists related to hyperv replication errors'
    severity: 0
    enabled: true
    evaluationFrequency: 'PT1H'
    scopes: [monitoring_workspace_id]
    targetResourceTypes: ['Microsoft.OperationalInsights/workspaces']
    windowSize: 'PT1H'
    criteria: {
      allOf: [
        {
          query: 'Event | where EventID in (32022, 32332, 32354, 32086, 33680, 32552, 32088, 32315)'
          timeAggregation: 'Count'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    actions: {
      actionGroups: [support_action_group.id]
    }
  }
  tags: common_tags
}

var disks_space_alert_name = 'logical_disks_free_space_alert'
resource disks_space_alert 'microsoft.insights/scheduledqueryrules@2023-03-15-preview' = {
  name: disks_space_alert_name
  location: location
  properties: {
    enabled: true
    displayName: disks_space_alert_name
    description: 'Alert (critical) if at least a disk has less space than expected'
    severity: 0
    evaluationFrequency: 'P1D'
    scopes: [monitoring_workspace_id]
    targetResourceTypes: ['Microsoft.OperationalInsights/workspaces']
    windowSize: 'P1D'
    criteria: {
      allOf: [
        {
          query: '''Perf
          | where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
          | where strlen(InstanceName) < 5 and InstanceName endswith ":"
          | summarize arg_max(TimeGenerated, *) by Computer, InstanceName
          | where CounterValue < 15'''
          timeAggregation: 'Count'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    actions: {
      actionGroups: [support_action_group.id]
    }
  }
  tags: common_tags
}


