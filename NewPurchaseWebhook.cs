using System.Net;
using Azure;
using Azure.Storage.Blobs;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace PR.AzureFuncs;

public class NewPurchaseWebhook
{
    private readonly ILogger<NewPurchaseWebhook> _logger;

    public NewPurchaseWebhook(ILogger<NewPurchaseWebhook> logger)
    {
        _logger = logger;
    }
    
    record NewOrderWebhook(int productId, int quantity, 
            string customerName, string customerEmail, decimal purchasePrice);

    public class NewPurchaseWebhookResponse
    {
        [QueueOutput("neworders", Connection = "AzureWebJobsStorage")]
        public NewOrderMessage? Message { get; set; }
        public HttpResponseData? HttpResponse { get; set; }
        [CosmosDBOutput("azurefuncs","orders",Connection ="CosmosDbConnection")]
        public OrderDocument? OrderDocument { get; set; }

    }
/*
the bindings that Azure Functions offers for working with databases and focusing particularly on Azure SQL and Azure Cosmos DB, 
and incorporate existing database access code, 
such as Entity Framework Core, into an Azure Functions application by making use of dependency injection
*/
    [Function(nameof(NewPurchaseWebhook))]
    public async Task<NewPurchaseWebhookResponse> Run([HttpTrigger(AuthorizationLevel.Function,  "post", Route ="purchase")] HttpRequestData req)
    {
        _logger.LogInformation("C# HTTP trigger function processed a request for order creation");
        
        var order = await req.ReadFromJsonAsync<NewOrderWebhook>();
         var message =   new NewOrderMessage(
                    Guid.NewGuid(), //order Id
	                order.productId, 
	                order.quantity,
	                order.customerName, 
	                order.customerEmail, 
                order.purchasePrice);

 var document = new OrderDocument() {
                id = message.orderId.ToString(),
                productId = order.productId,
                quantity = order.quantity,
                customerEmail = order.customerEmail,
                customerName = order.customerName,
                purchasePrice = order.purchasePrice
            };

        var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "text/plain; charset=utf-8");

            response.WriteString($"{order.customerName} purchased product {order.productId}!");
       
        return new NewPurchaseWebhookResponse
        {
            Message = message,
            HttpResponse = response,
            OrderDocument = document
        };
        
    }

      

    [Function(nameof(GetPurchase))]
    public IActionResult GetPurchase([HttpTrigger(AuthorizationLevel.Function, "get",
    Route ="purchase/{orderId:guid}")] //route constraint to say that the orderId should be a GUID.These are the route constraints for ASP.NET 
    HttpRequest req,
    [BlobInput("tickets/{orderId}.txt", Connection = "AzureWebJobsStorage")] BlobClient ticketClient,
    Guid orderId)
    {
         _logger.LogInformation($"Requested details of {orderId}");

        
        
        try
            {
                var ticketContents = ticketClient.DownloadContent().Value.Content.ToString();
                return new ContentResult
                {
                    StatusCode = (int)System.Net.HttpStatusCode.OK,
                    ContentType = "text/plain; charset=utf-8",
                    Content = ticketContents
                };
            }
            catch (RequestFailedException rfe) when (rfe.ErrorCode == "BlobNotFound")
            {
                _logger.LogError(rfe, $"Order {orderId} does not exist");
                 return new ContentResult
                {
                    StatusCode = (int)System.Net.HttpStatusCode.NotFound,
                };
            }
    }
}