$SUBSCRIPTION = "P8-Real Hands-On Labs"
$RESOURCE_GROUP = "1-0fea1aea-playground-sandbox"
$LOCATION = "eastasia"
$APIM_SERVICE_NAME = "apimmypetstore"
$PDT_ID_NAME = "mypetstore"
# log in and choose the subscription you want to work with
# username: cloud_user_p_3153c650@realhandsonlabs.com
# password: fe&3fVzC

az apim create `
    --name $APIM_SERVICE_NAME `
    --resource-group $RESOURCE_GROUP `
    --publisher-name petstore `
    --publisher-email prasanna@gmail.com `
    --location $LOCATION `
    --sku-name standard `
    --no-wait


az apim show `
    --name $APIM_SERVICE_NAME `
    --resource-group $RESOURCE_GROUP `
    --output table

az apim api import `
    --resource-group $RESOURCE_GROUP `
    --service-name $APIM_SERVICE_NAME `
    --path "/petstore" `
    --api-id petstore-api `
    --specification-url "https://petstore.swagger.io/v2/swagger.json" `
    --specification-format OpenApi `
    --display-name "Swagger Petstore API" `
    --description "A sample API for pet store operations."


az apim product create `
    --resource-group $RESOURCE_GROUP `
    --service-name $APIM_SERVICE_NAME `
    --product-id $PDT_ID_NAME `
    --product-name $PDT_ID_NAME `
    --description "petstore pdt policy" `
    --subscription-required true `
    --state published


az apim product list `
    --resource-group $RESOURCE_GROUP `
    --service-name $APIM_SERVICE_NAME

$API_ID = az apim api list --resource-group $RESOURCE_GROUP --service-name $APIM_SERVICE_NAME --query "[1].name" -o tsv

az apim product api add `
    --resource-group $RESOURCE_GROUP `
    --service-name $APIM_SERVICE_NAME `
    --product-id $PDT_ID_NAME `
    --api-id $API_ID


az apim api revision create `
    --resource-group $RESOURCE_GROUP `
    --service-name $APIM_SERVICE_NAME `
    --api-id $API_ID `
    --api-revision v1 `
    --api-revision-description "petstore api v1"

$RESOURCE_GROUP = "azure-funcs-resource"
$LOCATION = "(Asia Pacific) Australia Southeast" # change this to a location near you, (use az account list-locaions -o table)

# create a resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

$RANDOM_IDENTIFIER = "1987" # replace this with your own random number

$STORAGE_ACC_NAME = "azdd$RANDOM_IDENTIFIER" 
# create a storage account
az storage account create --name $STORAGE_ACC_NAME --resource-group $RESOURCE_GROUP --sku "Standard_LRS"

# note: app insights creation is now automatically part of az functionapp create

# create a new function app using the consumption plan
$FUNCTION_APP = "azdd$RANDOM_IDENTIFIER" # also needs to be globally unique

az functionapp create -n $FUNCTION_APP `
    --resource-group $RESOURCE_GROUP `
    --storage-account $STORAGE_ACC_NAME `
    --consumption-plan-location $LOCATION `
    --functions-version "4" `
    --runtime "dotnet-isolated" `
    --runtime-version "8"

# our function app uses a cosmos db database
# for samples see https://learn.microsoft.com/en-us/azure/cosmos-db/scripts/cli/nosql/serverless
$COSMOSDB_ACCOUNT = "azdd$RANDOM_IDENTIFIER"
$COSMOSDB_DATABASE = "azurefuncs"
$COSMOSDB_CONTAINER = "orders"
$COSMOSDB_PARTITIONKEY = "/customerEmail"
az cosmosdb create --name $COSMOSDB_ACCOUNT `
    --resource-group $RESOURCE_GROUP `
    --default-consistency-level Eventual `
    --locations regionName="$LOCATION" `
    failoverPriority=0 isZoneRedundant=False `
    --capabilities EnableServerless

# create a CosmosDB database
az cosmosdb sql database create --account-name $COSMOSDB_ACCOUNT `
    --resource-group $RESOURCE_GROUP `
    --name $COSMOSDB_DATABASE

# create the container
az cosmosdb sql container create --account-name $COSMOSDB_ACCOUNT `
    --resource-group $RESOURCE_GROUP `
    --database-name $COSMOSDB_DATABASE `
    --name $COSMOSDB_CONTAINER `
    --partition-key-path $COSMOSDB_PARTITIONKEY


# Get the Azure Cosmos DB connection string.
#az cosmosdb show --name $COSMOSDB_ACCOUNT --resource-group $RESOURCE_GROUP
#az cosmosdb show --name azurefunc-payment --resource-group 1-8f007a6d-playground-sandbox
$COSMOSDB_CONNECTION_STRING = az cosmosdb keys list `
    --name $COSMOSDB_ACCOUNT `
    --resource-group $RESOURCE_GROUP `
    --type "connection-strings" `
    --query "connectionStrings[0].connectionString" `
    -o tsv


# Configure function app settings to use the Azure Cosmos DB connection string.
az functionapp config appsettings set `
    --name $FUNCTION_APP `
    --resource-group $RESOURCE_GROUP `
    --setting "CosmosDbConnection=$COSMOSDB_CONNECTION_STRING"

# To clean up...
az group delete --name $RESOURCE_GROUP