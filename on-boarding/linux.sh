# Add the service principal application ID and secret here
ServicePrincipalId="<ENTER SERVICE PRINCIPAL HERE>";
ServicePrincipalClientSecret="<ENTER SECRET HERE>";


export subscriptionId="<ENTER SUBSCRIPTION ID HERE>";
export resourceGroup="<ENTER RESOURCE GROUP NAME HERE>";
export tenantId="<ENTER TENANT ID HERE>";
export location="<ENTER LOCATION HERE>";
export authType="principal";
export correlationId="e06f2eb7-54c0-4130-b693-b564fb68c223";
export cloud="AzureCloud";


# Download the installation package
LINUX_INSTALL_SCRIPT="/tmp/install_linux_azcmagent.sh"
if [ -f "$LINUX_INSTALL_SCRIPT" ]; then rm -f "$LINUX_INSTALL_SCRIPT"; fi;
output=$(wget https://gbl.his.arc.azure.com/azcmagent-linux -O "$LINUX_INSTALL_SCRIPT" 2>&1);
if [ $? != 0 ]; then wget -qO- --method=PUT --body-data="{\"subscriptionId\":\"$subscriptionId\",\"resourceGroup\":\"$resourceGroup\",\"tenantId\":\"$tenantId\",\"location\":\"$location\",\"correlationId\":\"$correlationId\",\"authType\":\"$authType\",\"operation\":\"onboarding\",\"messageType\":\"DownloadScriptFailed\",\"message\":\"$output\"}" "https://gbl.his.arc.azure.com/log" &> /dev/null || true; fi;
echo "$output";

# Install the hybrid agent
bash "$LINUX_INSTALL_SCRIPT";
sleep 5;

# Run connect command
sudo azcmagent connect --service-principal-id "$ServicePrincipalId" --service-principal-secret "$ServicePrincipalClientSecret" --resource-group "$resourceGroup" --tenant-id "$tenantId" --location "$location" --subscription-id "$subscriptionId" --cloud "$cloud" --tags 'Category=ND,Location=ND,Supplier=ND' --correlation-id "$correlationId";
