using System.IO;
using System.Threading.Tasks;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace PR.AzureFuncs;

public class NewBlobTrigger
{
    private readonly ILogger<NewBlobTrigger> _logger;

    public NewBlobTrigger(ILogger<NewBlobTrigger> logger)
    {
        _logger = logger;
    }

    [Function(nameof(NewBlobTrigger))]
    public async Task Run([BlobTrigger("tickets/{name}", Connection = "AzureWebJobsStorage")] Stream stream, string name)
    {
        using var blobStreamReader = new StreamReader(stream);
        var content = await blobStreamReader.ReadToEndAsync();
        _logger.LogInformation("C# Blob trigger function Processed blob\n Name: {name} \n Data: {content}", name, content);
    }

    [Function(nameof(NewBlobTrigger2))]
        public async Task NewBlobTrigger2([BlobTrigger("tickets2/{name}", Connection = "AzureWebJobsStorage")] 
            BlobClient blobClient, string name)
        {
            var content = (await blobClient.DownloadContentAsync()).Value.Content.ToString();
            var props = await blobClient.GetPropertiesAsync();
            _logger.LogInformation($"C# Blob trigger function Processed blob\n Name: {name} \n" +
                $"Data: {content} \n" +
                $"{props.Value.LastModified} {props.Value.ContentLength} {props.Value.ContentType}");
        }
}