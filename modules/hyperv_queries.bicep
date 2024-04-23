@description('Specifies the location for resources.')
param location string 

@description('Specifies common tags for all resources')
param common_tags object

resource this 'Microsoft.OperationalInsights/queryPacks@2019-09-01' = {
  name: 'HyperV'
  location: location
  tags: common_tags
  properties:{
  }
}

param query1_name string = 'HyperV: Logical Processor (% Total Run Time)'
resource query1 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query1_name)
  properties: {
    displayName: '[CP] - ${query1_name}'
    body: '''Perf
    | where ObjectName == "Hyper-V Hypervisor Logical Processor" and CounterName == "% Total Run Time"
    | where InstanceName == "_Total"
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

param query2_name string = 'HyperV: Dynamic Memory Balancer (Average Pressure)'
resource query2 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query2_name)
  properties: {
    displayName: '[CP] - ${query2_name}'
    body: '''Perf
    | where ObjectName == "Hyper-V Dynamic Memory Balancer" and CounterName == "Average Pressure"
    | summarize avg=avg(CounterValue) by bin(TimeGenerated, 30m), Computer
    | render timechart '''
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

param query3_name string = 'HyperV: Virtual Processor (% Total Run Time Graph)'
resource query3 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query3_name)
  properties: {
    displayName: '[CP] - ${query3_name}'
    body: '''Perf
    | where ObjectName == "Hyper-V Hypervisor Virtual Processor" and CounterName == "% Total Run Time"
    | where InstanceName != "_Total"
    | project
        Computer,
        VirtualMachine = substring(InstanceName, 0, indexof(InstanceName, ":")),
        VirtualProcessor = substring(InstanceName, indexof(InstanceName, ":") + 1),
        CounterValue
    | summarize avg=avg(CounterValue) by Computer, VirtualMachine, VirtualProcessor
    | summarize total=count(), over=countif(avg > 80) by Computer, VirtualMachine
    | project
        Computer,
        VirtualMachine,
        value=iff(over == 0, "Healty", iff(total > over, "Warning", "Critical"))
    | summarize
        healty=countif(value == "Healty"),
        warning=countif(value == "Warning"),
        critical=countif(value == "Critical")
        by Computer
    | render columnchart'''
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

param query4_name string = 'Hyper-V: Virtual Processor (% Total Run Time List)'
resource query4 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query4_name)
  properties: {
    displayName: '[CP] - ${query4_name}'
    body: '''Perf
    | where ObjectName == "Hyper-V Hypervisor Virtual Processor" and CounterName == "% Total Run Time"
    | where InstanceName != "_Total"
    | project
        Computer,
        VirtualMachine = substring(InstanceName, 0, indexof(InstanceName, ":")),
        VirtualProcessor = substring(InstanceName, indexof(InstanceName, ":") + 1),
        CounterValue
    | summarize avg=avg(CounterValue) by Computer, VirtualMachine, VirtualProcessor
    | summarize total=count(), over=countif(avg > 80) by Computer, VirtualMachine
    | project
        Computer,
        VirtualMachine,
        Status=iff(over == 0, "Healty", iff(total > over, "Warning", "Critical"))
    | where Status == "Warning" or Status == "Critical"
    | order by Computer, VirtualMachine, Status'''
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

param query5_name string = 'Hyper-V: Dynamic Memory VM (Average Pressure Graph)'
resource query5 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query5_name)
  properties: {
    displayName: '[CP] - ${query5_name}'
    body: '''Perf
    | where ObjectName == "Hyper-V Dynamic Memory VM" and CounterName == "Average Pressure"
    | summarize avg=avg(CounterValue) by Computer, InstanceName
    | project Computer, VirtualMachine=InstanceName, status=iif(avg < 80, "Healty", iif(avg < 100, "Warning", "Critical"))
    | summarize
        healty=countif(status == "Healty"),
        warning=countif(status == "Warning"),
        critical=countif(status == "Critical")
        by Computer
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

param query6_name string = 'Hyper-V: Dynamic Memory VM (Average Pressure List)'
resource query6 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query6_name)
  properties: {
    displayName: '[CP] - ${query6_name}'
    body: '''Perf
    | where ObjectName == "Hyper-V Dynamic Memory VM" and CounterName == "Average Pressure"
    | summarize avg=avg(CounterValue) by Computer, InstanceName
    | project Computer, VirtualMachine=InstanceName, status=iif(avg < 80, "Healty", iif(avg < 100, "Warning", "Critical"))
    | summarize
        healty=countif(status == "Healty"),
        warning=countif(status == "Warning"),
        critical=countif(status == "Critical")
        by Computer
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

param query7_name string = 'Hyper-V: Event errors (Aggregated graph)'
resource query7 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query7_name)
  properties: {
    displayName: '[CP] - ${query7_name}'
    body: '''Event
    | where EventID in (32022, 32332, 32354, 32086, 33680, 32552, 32088, 32315)
    | summarize Count=count() by Computer, EventID
    | project Computer, Count, tostring(EventID)  
    | render columnchart '''
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

param query8_name string = 'Hyper-V: Event errors (List)'
resource query8 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: this
  name: guid(resourceGroup().id, query8_name)
  properties: {
    displayName: '[CP] - ${query8_name}'
    body: '''Event
    | where EventID in (32022, 32332, 32354, 32086, 33680, 32552, 32088, 32315)
    | summarize Count=count() by Computer, EventID, RenderedDescription
    | project Computer, tostring(EventID), Count, RenderedDescription'''
    description: query8_name
    related: {
      categories: [
        'monitor'
      ]
    }
    tags: {
      
    }
  }
}
