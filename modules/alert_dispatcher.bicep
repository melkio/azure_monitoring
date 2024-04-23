@description('Specifies communication service name.')
param communication_service_name string 

@description('Specifies email communication service name.')
param email_service_name string 

@description('Specifies common tags for all resources')
param common_tags object

var europe_data_location = 'Europe'

resource email_service 'Microsoft.Communication/emailServices@2023-06-01-preview' = {
  name: email_service_name
  location: 'global'
  tags: union(common_tags, { context: 'monitoring' })
  properties: {
    dataLocation: europe_data_location
  }
}

resource email_domain 'Microsoft.Communication/emailServices/domains@2023-06-01-preview' = {
  parent: email_service
  name: 'AzureManagedDomain'
  location: 'global'
  tags: union(common_tags, { context: 'monitoring' })
  properties: {
    domainManagement: 'AzureManaged'
    userEngagementTracking: 'Disabled'
  }
}

resource communication_service 'Microsoft.Communication/CommunicationServices@2023-06-01-preview' = {
  name: communication_service_name
  location: 'global'
  tags: union(common_tags, { context: 'monitoring' })
  properties: {
    dataLocation: europe_data_location
    linkedDomains: [email_domain.id]
  }
}

resource email_sender 'Microsoft.Communication/emailServices/domains/senderusernames@2023-06-01-preview' = {
  name: 'donotreply'
  parent: email_domain
  properties: {
    username: 'DoNotReply'
    displayName: 'DoNotReply'
  }
}
