using System.Net;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;

namespace Company.Function
{
    public class GetResumeCounter
    {
        private readonly ILogger _logger;

        public GetResumeCounter(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<GetResumeCounter>();
        }

        [Function("GetResumeCounter")]
        public MultiResponse Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequestData req,
            [CosmosDBInput(databaseName: "AzureResume", containerName: "Counter", Connection = "AzureResumeConnectionString", Id = "1", PartitionKey = "1")] Counter counter)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");

            counter.Count += 1;

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            response.WriteString(JsonConvert.SerializeObject(counter));

            // Return both the HTTP response and the document to update CosmosDB
            return new MultiResponse
            {
                Document = counter,
                HttpResponse = response
            };
        }
    }

    // Class to handle multiple outputs (HTTP Response + CosmosDB Document Update)
    public class MultiResponse
    {
        [CosmosDBOutput(databaseName: "AzureResume", containerName: "Counter", Connection = "AzureResumeConnectionString", CreateIfNotExists = false)]
        public Counter Document { get; set; }

        public HttpResponseData HttpResponse { get; set; }
    }
}
