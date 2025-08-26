$USER_NAME="cloud_user_p_63fda2d9@realhandsonlabs.com"
$PASSWORD="7YQV^%H5"
$SUBSCRIPTION = "P4-Real Hands-On Labs"
$RESOURCE_GROUP = "1-bc5d8a7e-playground-sandbox"
$LOCATION = "eastasia"
$APIM_SERVICE_NAME = "apimmypetstore-1"
$PDT_ID_NAME = "mypetstore-1"
# log in and choose the subscription you want to work with
# username: cloud_user_p_3153c650@realhandsonlabs.com
# password: fe&3fVzC
#Write-Host "Azure login with creds"
#az login --username $USER_NAME --password $PASSWORD

#Write-Host "Deleting APIM Service -- "$APIM_SERVICE_NAME
#az apim deletedservice purge --service-name $APIM_SERVICE_NAME --location $LOCATION

Write-Host "Creating APIM Service -- "$APIM_SERVICE_NAME
az apim create `
    --name $APIM_SERVICE_NAME `
    --resource-group $RESOURCE_GROUP `
    --publisher-name petstore `
    --publisher-email prasanna@gmail.com `
    --location $LOCATION `
    --sku-name standard `
    --no-wait

$STATE=""
do {
    # Get the provisioning state of the API Management service
    $STATE = az apim show --name $APIM_SERVICE_NAME --resource-group $RESOURCE_GROUP --query "provisioningState" -o tsv
    Write-Host "Service is still provisioning.. $STATE"

    # Check if the state is not "Succeeded" or "Failed"
    if ($STATE -ne "Succeeded" -and $STATE -ne "Failed") {
        Write-Host "Service is still provisioning... Current state: $STATE. Waiting for 30 seconds."
        Start-Sleep -Seconds 30
    }

} while ($STATE -ne "Succeeded" -and $STATE -ne "Failed")
if ($STATE -eq "Succeeded") {
    Write-Host "APIM Service created and showing details ...."
    Start-Sleep -Seconds 5
    az apim show `
    --name $APIM_SERVICE_NAME `
    --resource-group $RESOURCE_GROUP `
    --output table

Write-Host "Importing the swagger API... "
Start-Sleep -Seconds 5

az apim api import `
    --resource-group $RESOURCE_GROUP `
    --service-name $APIM_SERVICE_NAME `
    --path "/petstore" `
    --api-id petstore-api `
    --specification-url "https://petstore.swagger.io/v2/swagger.json" `
    --specification-format OpenApi `
    --display-name "Swagger Petstore API" `
    --description "A sample API for pet store operations."


Write-Host "Creating the product... "
Start-Sleep -Seconds 10

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

Write-Host "Adding the product to ... $APIM_SERVICE_NAME "
Start-Sleep -Seconds 10

az apim product api add `
    --resource-group $RESOURCE_GROUP `
    --service-name $APIM_SERVICE_NAME `
    --product-id $PDT_ID_NAME `
    --api-id $API_ID

Write-Host "Creating version for - $APIM_SERVICE_NAME "
Start-Sleep -Seconds 10
az apim api revision create `
    --resource-group $RESOURCE_GROUP `
    --service-name $APIM_SERVICE_NAME `
    --api-id $API_ID `
    --api-revision v1 `
    --api-revision-description "petstore api v1"
}




    