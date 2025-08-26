using System;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace PR.AzureFuncs;

public class GenerateReport
{
    private readonly ILogger _logger;

    public GenerateReport(ILoggerFactory loggerFactory)
    {
        _logger = loggerFactory.CreateLogger<GenerateReport>();
    }

    [Function(nameof(GenerateReport))]
    public async Task Run([TimerTrigger("0 */1 * * * *")] TimerInfo myTimer,
    [BlobInput("tickets", Connection = "AzureWebJobsStorage")] BlobContainerClient ticketsClient)
    {

        /*
        TimerTrigger actually uses a Blob storage container to ensure that only one instance of your Function app actually runs the scheduled code. 
        And since we're running locally and the Functions runtime has got no access to Azure Blob storage, it can't do that.
        in local.settings.json file, fill in a value for the AzureWebJobsStorage connection string as UseDevelopmentStorage=true
        */
        _logger.LogInformation("C# Timer trigger function executed at: {executionTime}", DateTime.Now);

        if (myTimer.ScheduleStatus is not null)
        {
            _logger.LogInformation("Next timer schedule at: {nextSchedule}", myTimer.ScheduleStatus.Next);
        }
        
         await foreach(var f in ticketsClient.GetBlobsAsync())
            {
                var blob = ticketsClient.GetBlobClient(f.Name);
                var props = await blob.GetPropertiesAsync();
                if (DateTime.Now > props.Value.CreatedOn.AddDays(1))
                {
                    await blob.DeleteAsync();
                }
                else
                {
                    _logger.LogInformation($"Received order {f.Name}");
                }
            }
    }
}