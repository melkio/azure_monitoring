### Backup infrastructure - Backup management servers

```
CoreAzureBackup
| where OperationName  == "BackupManagementServer"
| summarize arg_max(TimeGenerated, *) by BackupManagementServerName
| join kind=inner (CoreAzureBackup
| where OperationName == "ProtectedContainerAssociation"
| summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId) on BackupManagementServerUniqueId
| summarize ProtectedServerCount=count() by Name=BackupManagementServerName, Version=AzureBackupAgentVersion,  AzureBackupAgentVersion=BackupManagementServerOSVersion
```

## Backup items distribution - List

```
_AzureBackup_GetBackupInstances
| summarize Count=countif(ProtectionInfo == "Protected") by DatasourceType
```

## Backup items distribution - Graph

```
_AzureBackup_GetBackupInstances
| summarize Count=countif(ProtectionInfo == "Protected") by DatasourceType
| render piechart 
```

## Active alerts

```
AddonAzureBackupAlerts
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
| order by AlertSeverity asc, ProtectedContainerFriendlyName asc 
```

## Alert summary - Alert count by type and server

```
AddonAzureBackupAlerts
| summarize AlertCount=count() by BackupManagementServerUniqueId, AlertType
| join kind=inner  (CoreAzureBackup
    | where OperationName == "BackupManagementServer"
    | summarize arg_max(TimeGenerated, *) by BackupManagementServerUniqueId
    | project BackupManagementServerUniqueId, BackupManagementServerName)
    on BackupManagementServerUniqueId
| project BackupManagementServerName, AlertCount, AlertType
| render columnchart 
```

## Jobs by status over time - Completed / Failed

```
AddonAzureBackupJobs
| where JobOperationSubType != "Recovery point_Log"
| summarize Failed=countif(JobStatus == "Failed"), Completed=countif(JobStatus == "Completed") by bin(TimeGenerated, 1d)
| order by TimeGenerated asc
| render columnchart 
```

## Failed jobs by failure code
```
AddonAzureBackupJobs
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
| render piechart 
```


