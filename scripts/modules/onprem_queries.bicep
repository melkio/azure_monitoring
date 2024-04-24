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

var query1_name = 'OnPrem: CPU utilization'
resource query_1 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query1_name)
  properties: {
    displayName: '[CP] - ${query1_name}'
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

var query2_name = 'OnPrem: Disk usage'
resource query_2 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query2_name)
  properties: {
    displayName: '[CP] - ${query2_name}'
    body: '''Perf
    | where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
    | where strlen(InstanceName) < 5 and InstanceName endswith ":"
    | summarize arg_max(TimeGenerated, *) by Computer, InstanceName
    | project Status = iif(CounterValue > 50, "Healty", iif(CounterValue < 15, "Critical", "Warning"))
    | summarize count() by Status
    | render piechart'''
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

var query3_name = 'OnPrem: Critical disks'
resource query_3 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query3_name)
  properties: {
    displayName: '[CP] - ${query3_name}'
    body: '''Perf
    | where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
    | where strlen(InstanceName) < 5 and InstanceName endswith ":"
    | summarize arg_max(TimeGenerated, *) by Computer, InstanceName
    | project Status = iif(CounterValue > 50, "Healty", iif(CounterValue < 15, "Critical", "Warning"))
    | summarize count() by Status
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
