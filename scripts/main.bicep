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

@description('Specifies eventhub namespace name')
param alert_event_hub_namespace_name string

@description('Specifies app managed environment name.')
param app_environment_name string

@description('Specifies communication service name.')
param communication_service_name string 

@description('Specifies email communication service name.')
param email_service_name string 

@description('Specifies log analytics reader service principal client id.')
param log_analytics_reader_client_id string

@secure()
@description('Specifies log analytics reader service principal client secret.')
param log_analytics_reader_client_secret string

@description('Specifies alert dispatcher app version.')
param alert_dispather_app_version string

@description('Specifies alert recipient email.')
param alert_recipient_email string


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

module alert_rules './modules/alert_rules.bicep' = {
  name: 'alert_rules'
  scope: this
  params: {
    location: location
    alert_event_hub_namespace_name: alert_event_hub_namespace_name
    monitoring_workspace_id: infrastructure.outputs.monitoring_workspace_id
    dpm_workspace_id: infrastructure.outputs.dpm_workspace_id
    common_tags: common_tags
  }
}

module alert_dispatcher './modules/alert_dispatcher.bicep' = {
  name: 'alert_dispatcher'
  scope: this
  params: {
    location: location
    monitoring_workspace_id: infrastructure.outputs.monitoring_workspace_id
    dpm_workspace_id: infrastructure.outputs.dpm_workspace_id
    log_analytics_reader_client_id: log_analytics_reader_client_id
    log_analytics_reader_client_secret: log_analytics_reader_client_secret
    app_environment_name: app_environment_name
    communication_service_name: communication_service_name
    email_service_name: email_service_name
    alert_dispather_app_version: alert_dispather_app_version
    alert_recipient_email: alert_recipient_email
    common_tags: common_tags
  }
}

