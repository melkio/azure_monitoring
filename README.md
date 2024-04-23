Create a `current.bicepparam` in the root folder. 
A sample of params file is:

```
using './main.bicep'

param defender_workspace_name = 'DEFENDER_WORKSPACE_NAME'
param dpm_workspace_name = 'DPM_WORKSPACE_NAME'
param monitoring_workspace_name = 'MONITORING_WORKSPACE_NAME'
param alert_event_hub_namespace_name = 'ALERT_EVENT_HUB_NAMESPACE_NAME'
```

To verify what will happen, execute the command: `az deployment sub what-if --name monitor-deployment --location westeurope --template-file main.bicep --parameters current.bicepparam`


To apply changes, execute the command: `az deployment sub create --name monitor-deployment --location westeurope --template-file main.bicep --parameters current.bicepparam`