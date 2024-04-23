targetScope = 'subscription'

@description('Specifies the location for resources.')
param location string = 'westeurope'

@description('Specifies the name of the resource group.')
param resource_group_name string = 'monitoring_support'

@description('Specifies monitoring log analytics workspace name.')
param monitoring_workspace_name string 

@description('Specifies dpm log analytics workspace name.')
param dpm_workspace_name string 

@description('Specifies defender log analytics workspace name.')
param defender_workspace_name string 

@description('Specifies common data collection rule name')
param common_data_collection_rule_name string = 'CodicePlastico-Monitoring-Common'

@description('Specifies hyperv data collection rule name')
param hyperv_data_collection_rule_name string = 'CodicePlastico-Monitoring-HyperV'

var common_tags = {
  environment: 'infrastructure'
  owner: 'codiceplastico'
  script: 'true'
}

resource this 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resource_group_name
  location: location
  tags: common_tags
}

module infrastructure './modules/infrastructure.bicep' = {
  name: 'infrastructure'
  scope: this
  params: {
    location: location
    monitoring_workspace_name: monitoring_workspace_name
    dpm_workspace_name: dpm_workspace_name
    defender_workspace_name: defender_workspace_name
    common_data_collection_rule_name: common_data_collection_rule_name
    hyperv_data_collection_rule_name: hyperv_data_collection_rule_name
    common_tags: common_tags
  }
}

module onprem_queries './modules/onprem_queries.bicep' = {
  name: 'onprem_queries'
  scope: this
  params: {
    location: location
    common_tags: common_tags
  }
}

module dpm_queries './modules/dpm_queries.bicep' = {
  name: 'dpm_queries'
  scope: this
  params: {
    location: location
    common_tags: common_tags
  }
}

module hyperv_queries './modules/hyperv_queries.bicep' = {
  name: 'hyperv_queries'
  scope: this
  params: {
    location: location
    common_tags: common_tags
  }
}
