using System.Threading.Tasks;
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

    [Function(nameof(NewPurchaseWebhook))]
    public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function,  "post", Route ="purchase")] HttpRequestData req)
    {
        _logger.LogInformation("C# HTTP trigger function processed a request.");
        var order = await req.ReadFromJsonAsync<NewOrderWebhook>();
       
        return new ContentResult
        {
            StatusCode = (int)System.Net.HttpStatusCode.OK,
            ContentType = "text/plain; charset=utf-8",
            Content = $"Order Details: {order.customerName} purchased {order.productId}!"
        };
       
       // return new OkObjectResult($"Order Details: {order.customerName} purchased {order.productId}!");
    }

      record NewOrderWebhook(int productId, int quantity, 
            string customerName, string customerEmail, decimal purchasePrice);

    [Function(nameof(GetPurchase))]
    public IActionResult GetPurchase([HttpTrigger(AuthorizationLevel.Function, "get","purchase")] HttpRequest req)
    {
        _logger.LogInformation("C# HTTP trigger function processed a request.");
        var userAgent = req.Headers.GetCommaSeparatedValues("User-Agent");
        var name = req.Query["name"].ToString() ?? "Anonyms";
    /*    return new ContentResult
    {
        StatusCode = (int)System.Net.HttpStatusCode.OK,
        ContentType = "text/plain; charset=utf-8",
        Content = "Welcome to Azure Functions!"
    };*/
        return new OkObjectResult($"Welcome {name}!");
    }
}