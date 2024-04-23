@description('Specifies the location for resources.')
param location string 

@description('Specifies common tags for all resources')
param common_tags object

resource this 'Microsoft.OperationalInsights/queryPacks@2019-09-01' = {
  name: 'OnPrem'
  location: location
  tags: common_tags
  properties:{
  }
}

resource query_1 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, 'OnPrem: CPU utilization')
  properties: {
    displayName: '[CP] - OnPrem: CPU utilization'
    body: '''Perf
    | where ObjectName == "Processor Information" and CounterName == "% Processor Time"
    | where InstanceName == "_Total"
    | join kind=inner ( 
        Perf
        | where ObjectName == "Processor Information" and CounterName == "% Processor Time"
        | where InstanceName == "_Total"
        | summarize avg(CounterValue) by Computer
        | order by avg_CounterValue desc 
        | take 5
    ) on $left.Computer == $right.Computer
    | summarize avg=avg(CounterValue) by bin(TimeGenerated, 30m), Computer
    | render timechart '''
    description: 'OnPrem: CPU utilization'
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
  name: guid(resourceGroup().id, 'OnPrem: Disk usage')
  properties: {
    displayName: '[CP] - OnPrem: Disk usage'
    body: '''Perf
    | where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
    | where strlen(InstanceName) < 5 and InstanceName endswith ":"
    | summarize arg_max(TimeGenerated, *) by Computer, InstanceName
    | project Status = iif(CounterValue > 50, "Healty", iif(CounterValue < 15, "Critical", "Warning"))
    | summarize count() by Status
    | render piechart'''
    description: 'OnPrem: Disk usage'
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
  name: guid(resourceGroup().id, 'OnPrem: Critical disks')
  properties: {
    displayName: '[CP] - OnPrem: Disk usage - Critical disks (less than 15% free space available)'
    body: '''Perf
    | where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
    | where strlen(InstanceName) < 5 and InstanceName endswith ":"
    | summarize arg_max(TimeGenerated, *) by Computer, InstanceName
    | project Status = iif(CounterValue > 50, "Healty", iif(CounterValue < 15, "Critical", "Warning"))
    | summarize count() by Status
    | render piechart'''
    description: 'OnPrem: Disk usage - Critical disks (less than 15% free space available)'
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}
