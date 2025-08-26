using Microsoft.AspNetCore.Server.Kestrel.Core;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

var builder = FunctionsApplication.CreateBuilder(args);

builder.ConfigureFunctionsWebApplication();

// Add your services and configuration here
builder.Services
    // This is where you add the synchronous I/O configuration
    .Configure<KestrelServerOptions>(options =>
    {
        options.AllowSynchronousIO = true;
    })
    .AddApplicationInsightsTelemetryWorkerService()
    .ConfigureFunctionsApplicationInsights();

var app = builder.Build();

app.Run();