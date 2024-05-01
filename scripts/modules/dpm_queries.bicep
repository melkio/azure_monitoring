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

var query1_name = 'DPM: Backup management servers'
resource query1 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query1_name)
  properties: {
    displayName: '[CP] - ${query1_name}'
    body: '''CoreAzureBackup
    | where OperationName  == "BackupManagementServer"
    | summarize arg_max(TimeGenerated, *) by BackupManagementServerName
    | join kind=inner (CoreAzureBackup
    | where OperationName == "ProtectedContainerAssociation"
    | summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId) on BackupManagementServerUniqueId
    | summarize ProtectedServerCount=count() by Name=BackupManagementServerName, Version=AzureBackupAgentVersion,  AzureBackupAgentVersion=BackupManagementServerOSVersion'''
    description: query1_name
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}

var query2_name = 'DPM: Backup items distribution (list)'
resource query2 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query2_name)
  properties: {
    displayName: '[CP] - ${query2_name}'
    body: '''_AzureBackup_GetBackupInstances 
    | summarize Count=countif(ProtectionInfo == "Protected") by DatasourceType'''
    description: query2_name
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}

var query3_name = 'DPM: Backup items distribution (graph)'
resource query3 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query3_name)
  properties: {
    displayName: '[CP] - ${query3_name}'
    body: '''_AzureBackup_GetBackupInstances 
    | summarize Count=countif(ProtectionInfo == "Protected") by DatasourceType 
    | render piechart'''
    description: query3_name
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}

var query4_name = 'DPM: Active alerts'
resource query4 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query4_name)
  properties: {
    displayName: '[CP] - ${query4_name}'
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
    description: query4_name
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}

var query5_name = 'DPM: Alert count by type and server'
resource query5 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query5_name)
  properties: {
    displayName: '[CP] - ${query5_name}'
    body: '''AddonAzureBackupAlerts
    | summarize AlertCount=count() by BackupManagementServerUniqueId, AlertType
    | join kind=inner  (CoreAzureBackup
        | where OperationName == "BackupManagementServer"
        | summarize arg_max(TimeGenerated, *) by BackupManagementServerUniqueId
        | project BackupManagementServerUniqueId, BackupManagementServerName)
        on BackupManagementServerUniqueId
    | project BackupManagementServerName, AlertCount, AlertType
    | render columnchart'''
    description: query5_name
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}

var query6_name = 'DPM: Jobs by status over time'
resource query6 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query6_name)
  properties: {
    displayName: '[CP] - ${query6_name}'
    body: '''AddonAzureBackupJobs
    | where JobOperationSubType != "Recovery point_Log"
    | summarize Failed=countif(JobStatus == "Failed"), Completed=countif(JobStatus == "Completed") by bin(TimeGenerated, 1d)
    | order by TimeGenerated asc
    | render columnchart'''
    description: query6_name
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}

var query7_name = 'DPM: Failed jobs by failure code'
resource query_7 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query7_name)
  properties: {
    displayName: '[CP] - ${query7_name}'
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
    | render piechart'''
    description: query7_name
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}



