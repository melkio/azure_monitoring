@description('Specifies the location for resources.')
param location string = 'westeurope'

@description('Specifies monitoring log analytics workspace name.')
param monitoring_workspace_name string 

@description('Specifies dpm log analytics workspace name.')
param dpm_workspace_name string 

@description('Specifies defender log analytics workspace name.')
param defender_workspace_name string 

@description('Specifies common data collection rule name')
param common_data_collection_rule_name string

@description('Specifies hyperv data collection rule name')
param hyperv_data_collection_rule_name string

// @description('Specifies iis data collection rule name')
// param iis_data_collection_rule_name string

@description('Specifies common tags for all resources')
param common_tags object

var data_collection_endpoint_name= '${location}-data-collection-endpoint'

resource monitoring_workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: monitoring_workspace_name
  location: location
  tags: union(common_tags, { context: 'monitoring' })
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
}

resource dpm_workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: dpm_workspace_name
  location: location
  tags: union(common_tags, { context: 'dpm' })
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
}

resource defender_workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: defender_workspace_name
  location: location
  tags: union(common_tags, { context: 'defender' })
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
}

resource data_collection_endpoint 'Microsoft.Insights/dataCollectionEndpoints@2022-06-01' = {
  name: data_collection_endpoint_name
  location: location
  tags: common_tags
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource common_data_collection_rule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: common_data_collection_rule_name
  location: location
  kind: 'Windows'
  properties: {
    dataSources: {
      performanceCounters: [
        {
          streams: ['Microsoft-Perf']
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\Processor Information(_Total)\\% Processor Time'
            '\\Processor Information(_Total)\\% Privileged Time'
            '\\Processor Information(_Total)\\% User Time'
            '\\LogicalDisk(_Total)\\% Free Space'
            '\\Network Interface(*)\\Bytes Total/sec'
            '\\Network Interface(*)\\Bytes Sent/sec'
            '\\Network Interface(*)\\Bytes Received/sec'
            '\\LogicalDisk(*)\\% Free Space'
            '\\Processor Information(*)\\% Processor Time'
            '\\Processor Information(*)\\% Privileged Time'
            '\\Processor Information(*)\\% User Time'
          ]
          name: 'common-perf-counter'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: monitoring_workspace.id
          name: monitoring_workspace.name
        }
      ]
    }
    dataFlows: [
      {
        streams: ['Microsoft-Perf']
        destinations: [monitoring_workspace.name]
      }
    ]
  }
  tags: common_tags
}

resource hyperv_data_collection_rule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: hyperv_data_collection_rule_name
  location: location
  kind: 'Windows'
  properties: {
    dataSources: {
      performanceCounters: [
        {
          streams: ['Microsoft-Perf']
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\Hyper-V Hypervisor Logical Processor(*)\\% Total Run Time'
            '\\Hyper-V Hypervisor Virtual Processor(*)\\% Total Run Time'
            '\\Hyper-V Hypervisor Root Virtual Processor(*)\\% Total Run Time'
            '\\Hyper-V Dynamic Memory Balancer(*)\\Available Memory'
            '\\Hyper-V Dynamic Memory Balancer(*)\\Average Pressure'
            '\\Hyper-V Dynamic Memory VM(*)\\Guest Visible Physical Memory'
            '\\Hyper-V Dynamic Memory VM(*)\\Physical Memory'
            '\\Hyper-V Dynamic Memory VM(*)\\Average Pressure'
          ]
          name: 'hyperv-perf-counter'
        }
      ]
      windowsEventLogs: [
        {
          streams: ['Microsoft-Event']
          xPathQueries: [
            'Microsoft-Windows-Hyper-V-VMMS-Admin!*[System[(Level=1 or Level=2 or Level=3)]]'
          ]
          name: 'hyperv-windows-event-logs'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: monitoring_workspace.id
          name: monitoring_workspace.name
        }
      ]
    }
    dataFlows: [
      {
        streams: ['Microsoft-Perf']
        destinations: [monitoring_workspace.name]
      }
      {
        streams: ['Microsoft-Event']
        destinations: [monitoring_workspace.name]
      }
    ]
  }
  tags: common_tags
}

output monitoring_workspace_id string = monitoring_workspace.properties.customerId
output dpm_workspace_id string = dpm_workspace.properties.customerId
output defender_workspace_id string = defender_workspace.properties.customerId

// resource iis_data_collection_rule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
//   name: iis_data_collection_rule_name
//   location: location
//   kind: 'Windows'
//   properties: {
//     dataCollectionEndpointId: data_collection_endpoint.id
//     streamDeclarations: {
//       'Custom-MyTable_CL': {
//         columns: [
//           {
//             name: 'TimeGenerated'
//             type: 'datetime'
//           }
//           {
//             name: 'RawData'
//             type: 'string'
//           }
//         ]
//       }
//     }
//     dataSources: {
//       iisLogs: [
//         {
//           streams: ['Microsoft-W3CIISLog']
//           name: 'iis-log'
//         }
//       ]
//     }
//     destinations: {
//       logAnalytics: [
//         {
//           workspaceResourceId: monitoring_workspace.id
//           name: monitoring_workspace.name
//         }
//       ]
//     }
//     dataFlows: [
//       {
//         streams: ['Microsoft-W3CIISLog']
//         destinations: [monitoring_workspace.name]
//         transformKql: 'source'
//         outputStream: 'Microsoft-W3CIISLog'
//       }
//     ]
//   }
//   tags: common_tags
// }
