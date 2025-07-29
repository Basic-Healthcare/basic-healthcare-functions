using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Azure.Storage.Files.DataLake;
using Azure.Identity;

namespace BasicHealthcareFunctions
{
    public static class HealthCheck
    {
        [FunctionName("HealthCheck")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = "health")] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("Health check endpoint called.");

            try
            {
                var healthStatus = new
                {
                    Status = "Healthy",
                    Timestamp = DateTime.UtcNow,
                    Version = "1.0.0",
                    Environment = Environment.GetEnvironmentVariable("AZURE_FUNCTIONS_ENVIRONMENT") ?? "Development",
                    DataLake = await CheckDataLakeConnectivity(log)
                };

                log.LogInformation("Health check completed successfully.");
                return new OkObjectResult(healthStatus);
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Health check failed.");
                
                var errorStatus = new
                {
                    Status = "Unhealthy",
                    Timestamp = DateTime.UtcNow,
                    Error = ex.Message
                };

                return new ObjectResult(errorStatus) { StatusCode = 503 };
            }
        }

        private static async Task<object> CheckDataLakeConnectivity(ILogger log)
        {
            try
            {
                var storageAccountName = Environment.GetEnvironmentVariable("DATA_LAKE_STORAGE_ACCOUNT");
                
                if (string.IsNullOrEmpty(storageAccountName))
                {
                    return new { Status = "Not Configured", Message = "Storage account name not found in configuration" };
                }

                // Use managed identity to authenticate
                var credential = new DefaultAzureCredential();
                var dataLakeServiceClient = new DataLakeServiceClient(
                    new Uri($"https://{storageAccountName}.dfs.core.windows.net"), 
                    credential);

                // Try to get account info to verify connectivity
                var accountInfo = await dataLakeServiceClient.GetAccountInfoAsync();
                
                log.LogInformation("Data Lake connectivity check successful.");
                return new { Status = "Connected", StorageAccount = storageAccountName };
            }
            catch (Exception ex)
            {
                log.LogWarning(ex, "Data Lake connectivity check failed.");
                return new { Status = "Disconnected", Error = ex.Message };
            }
        }
    }
}
