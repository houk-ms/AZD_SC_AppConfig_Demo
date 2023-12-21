# In the future, the logics to create sc will be integrated into azd (azd creates 
# service connector resources which will write binding configs either to AppConfig 
# or KeyVault). For now, we just use the script to do similar 


# Read and export environment variables from the .env file
export DefaultEnvName=$(head -n 1 .azure/config.json | awk '{print substr($0, 36, length($0)-37)}')
EnvFile=".azure/${DefaultEnvName}/.env"
while IFS= read -r line; do
    key="${line%%=*}"
    value="${line#*=}"
    value="${value%\"}"
    value="${value#\"}"
    export "$key=$value"
done < "$EnvFile"


export SubscriptionId=937bc588-a144-4083-8612-5f9ffbbddb14
export ServiceConnectorTeamObjectId=55491e97-df97-4834-b9ad-77a3690b77c3    # for demostration only
export ResourceGroupName=rg-$AZURE_ENV_NAME
export AppConfigName=appcs-${AZURE_CONTAINER_REGISTRY_NAME:2}
export CosmosAccountName=cosmos-${AZURE_CONTAINER_REGISTRY_NAME:2}


echo 'Pre-deploy hook begins ...'


# Authenticate to AzureCLI
echo '--> Step1. Authenticate to Azure CLI'
# az login > /dev/null
az account set -s $SubscriptionId


# Authenticate to AzureCLI
echo '--> Step2. Add data roles to access AppConfig and KeyVault'
az role assignment create \
    --assignee-object-id $ServiceConnectorTeamObjectId --assignee-principal-type Group \
    --role "App Configuration Data Owner" \
    --scope /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.AppConfiguration/configurationStores/$AppConfigName \
    > /dev/null

az keyvault set-policy \
    --name $AZURE_KEY_VAULT_NAME --resource-group $ResourceGroupName \
    --object-id $ServiceConnectorTeamObjectId \
    --secret-permissions get list set \
    > /dev/null


export CosmosConnectionString=$(az cosmosdb keys list \
        --type connection-strings \
        --name $CosmosAccountName \
        --resource-group $ResourceGroupName \
        --query "connectionStrings[0].connectionString" \
        --output tsv)


echo '--> Step3. Create bindings according to binding.yaml file'
# [web--api]
echo '-----> Create http binding for web and api'
# az appconfig kv set \
#     --key REACT_APP_API_BASE_URL \
#     --value $REACT_APP_API_BASE_URL \
#     -n $AppConfigName --yes > /dev/null
# az keyvault secret set \
#     --name REACT-APP-APPLICATIONINSIGHTS-CONNECTION-STRING \
#     --value $APPLICATIONINSIGHTS_CONNECTION_STRING \
#     --vault-name $AZURE_KEY_VAULT_NAME \
#     > /dev/null

# [api--cosmos]
echo '-----> Create secret binding for api and cosmos'
az appconfig kv set \
    --key API_ALLOW_ORIGINS \
    --value $API_CORS_ACA_URL  \
    -n $AppConfigName \
    --yes > /dev/null
az appconfig kv set \
    --key AZURE_COSMOS_DATABASE_NAME \
    --value $AZURE_COSMOS_DATABASE_NAME \
    -n $AppConfigName \
    --yes > /dev/null
az keyvault secret set \
    --name AZURE-COSMOS-CONNECTION-STRING \
    --value $CosmosConnectionString \
    --vault-name $AZURE_KEY_VAULT_NAME \
    > /dev/null

# [api-appinsights]
echo '-----> Create secret binding for api and monitoring'
az keyvault secret set \
    --name APPLICATIONINSIGHTS-CONNECTION-STRING \
    --value $APPLICATIONINSIGHTS_CONNECTION_STRING \
    --vault-name $AZURE_KEY_VAULT_NAME \
    > /dev/null

echo 'Pre-deploy hook ends ...'