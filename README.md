Create a `current.bicepparam` in the root folder. 
A sample of params file is:

```
using './main.bicep'

param defender_workspace_name = '99c767ac494043ef'
param dpm_workspace_name = 'c931e228bc14499d'
param monitoring_workspace_name = '200e94c860f1451f'
```

To verify what will happen, execute the command: `az deployment sub what-if --name monitor-deployment --location westeurope --template-file main.bicep --parameters current.bicepparam`


To apply changes, execute the command: `az deployment sub create --name monitor-deployment --location westeurope --template-file main.bicep --parameters current.bicepparam`