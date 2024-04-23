@description('Specifies the location for resources.')
param location string 

@description('Specifies common tags for all resources')
param common_tags object

resource this 'Microsoft.OperationalInsights/queryPacks@2019-09-01' = {
  name: 'DPM'
  location: location
  tags: common_tags
  properties:{
  }
}

resource query_1 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, 'DPM: Backup management servers')
  properties: {
    displayName: '[CP] - DPM: Backup management servers'
    body: '''CoreAzureBackup 
    | where OperationName  == "BackupManagementServer" 
    | summarize arg_max(TimeGenerated, *) by BackupManagementServerName 
    | join kind=inner (CoreAzureBackup 
    | where OperationName == "ProtectedContainerAssociation" 
    | summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId) on BackupManagementServerUniqueId 
    | summarize ProtectedServerCount=count() by Name=BackupManagementServerName, Version=AzureBackupAgentVersion,  AzureBackupAgentVersion=BackupManagementServerOSVersion'''
    description: 'DPM: Backup infrastructure (backup management servers)'
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}

resource query_2 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, 'DPM: Backup items distribution (list)')
  properties: {
    displayName: '[CP] - DPM: Backup items distribution (list)'
    body: '_AzureBackup_GetBackupInstances | summarize Count=countif(ProtectionInfo == "Protected") by DatasourceType'
    description: 'DPM: Backup items distribution (list)'
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}

resource query_3 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, 'DPM: Backup items distribution (graph)')
  properties: {
    displayName: '[CP] - DPM: Backup items distribution (graph)'
    body: '_AzureBackup_GetBackupInstances | summarize Count=countif(ProtectionInfo == "Protected") by DatasourceType | render piechart '
    description: 'DPM: Backup items distribution (graph)'
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}

resource query_4 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, 'DPM: Active alerts')
  properties: {
    displayName: '[CP] - DPM: Active alerts'
    body: '''AddonAzureBackupAlerts
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
    description: 'DPM: Active alerts'
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}

resource query_5 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, 'DPM: Alert count by type and server')
  properties: {
    displayName: '[CP] - DPM: Alert count by type and server'
    body: '''AddonAzureBackupAlerts
    | summarize AlertCount=count() by BackupManagementServerUniqueId, AlertType
    | join kind=inner  (CoreAzureBackup
        | where OperationName == "BackupManagementServer"
        | summarize arg_max(TimeGenerated, *) by BackupManagementServerUniqueId
        | project BackupManagementServerUniqueId, BackupManagementServerName)
        on BackupManagementServerUniqueId
    | project BackupManagementServerName, AlertCount, AlertType
    | render columnchart '''
    description: 'DPM: Alert summary (alert count by type and server)'
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}

resource query_6 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, 'DPM: Jobs by status over time')
  properties: {
    displayName: '[CP] - DPM: Jobs by status over time'
    body: '''AddonAzureBackupJobs
    | where JobOperationSubType != "Recovery point_Log"
    | summarize Failed=countif(JobStatus == "Failed"), Completed=countif(JobStatus == "Completed") by bin(TimeGenerated, 1d)
    | order by TimeGenerated asc
    | render columnchart'''
    description: 'DPM: Jobs by status over time (completed / failed)'
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}

resource query_7 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, 'DPM: Failed jobs by failure code')
  properties: {
    displayName: '[CP] - DPM: Failed jobs by failure code'
    body: '''AddonAzureBackupJobs
    | where JobOperationSubType != "Recovery point_Log"
    | where JobStatus == "Failed"
    | summarize Count=count() by JobFailureCode
    | order by Count desc 
    | extend Index=row_number()
    | where Index between (1 .. 9)
    | union ( 
        AddonAzureBackupJobs
        | where JobOperationSubType != "Recovery point_Log"
        | where JobStatus == "Failed"
        | summarize Count=count() by JobFailureCode
        | order by Count desc 
        | extend Index=row_number()
        | where Index > 9
        | summarize sum(Count)
        | project JobFailureCode="others", Count=sum_Count
    )
    | render piechart '''
    description: 'DPM: Failed jobs by failure code'
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}



