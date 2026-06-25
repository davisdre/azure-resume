using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Resume.Backend
{
    public static class GetResumeCounter
    {
        [Function("GetResumeCounter")]
        public static Tuple<IActionResult, CounterItem> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req,
            [CosmosDBInput(
                databaseName: "ResumeDatabase",
                containerName: "CounterContainer",
                Connection = "CosmosDBConnectionString",
                Id = "1",
                PartitionKey = "1")] CounterItem currentCounter,
            FunctionContext executionContext)
        {
            var logger = executionContext.GetLogger("GetResumeCounter");
            logger.LogInformation("Processing visitor counter metric event.");

            // Initialize document state if container is fresh or empty
            if (currentCounter == null)
            {
                currentCounter = new CounterItem
                {
                    Id = "1",
                    PartitionKey = "1",
                    Count = 0;
                };
            }

            // Increment traffic counter metric
            currentCounter.Count++;

            // Return modern Ok Object along with updated model via Cosmos DB Output binding
            var jsonResponse = new { count = currentCounter.Count };
            return new Tuple<IActionResult, CounterItem>(new OkObjectResult(jsonResponse), currentCounter);
        }
    }

    public class CounterItem
    {
        public string Id { get; set; } = string.Empty;
        public string PartitionKey { get; set; } = string.Empty;
        public int Count { get; set; }
    }
}