using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Azure.Storage.Files.DataLake;
using Azure.Identity;
using System.Text;
using System.Collections.Generic;
using System.Linq;

namespace BasicHealthcareFunctions
{
    public static class DataLakeOperations
    {
        [FunctionName("UploadToDataLake")]
        public static async Task<IActionResult> UploadFile(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = "datalake/upload/{container}/{fileName}")] HttpRequest req,
            string container,
            string fileName,
            ILogger log)
        {
            log.LogInformation($"Upload request for file: {fileName} to container: {container}");

            try
            {
                var storageAccountName = Environment.GetEnvironmentVariable("DATA_LAKE_STORAGE_ACCOUNT");
                if (string.IsNullOrEmpty(storageAccountName))
                {
                    return new BadRequestObjectResult("Storage account configuration not found.");
                }

                // Validate container name
                if (!IsValidContainer(container))
                {
                    return new BadRequestObjectResult("Invalid container name. Valid containers: raw, processed, curated");
                }

                // Use managed identity to authenticate
                var credential = new DefaultAzureCredential();
                var dataLakeServiceClient = new DataLakeServiceClient(
                    new Uri($"https://{storageAccountName}.dfs.core.windows.net"), 
                    credential);

                var fileSystemClient = dataLakeServiceClient.GetFileSystemClient(container);
                var fileClient = fileSystemClient.GetFileClient(fileName);

                // Read the request body
                using var reader = new StreamReader(req.Body);
                var content = await reader.ReadToEndAsync();

                // Upload the file
                using var stream = new MemoryStream(Encoding.UTF8.GetBytes(content));
                await fileClient.UploadAsync(stream, overwrite: true);

                log.LogInformation($"Successfully uploaded file: {fileName} to container: {container}");

                return new OkObjectResult(new
                {
                    Message = "File uploaded successfully",
                    Container = container,
                    FileName = fileName,
                    Timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                log.LogError(ex, $"Failed to upload file: {fileName}");
                return new ObjectResult(new { Error = ex.Message }) { StatusCode = 500 };
            }
        }

        [FunctionName("ListDataLakeFiles")]
        public static async Task<IActionResult> ListFiles(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = "datalake/list/{container}")] HttpRequest req,
            string container,
            ILogger log)
        {
            log.LogInformation($"List files request for container: {container}");

            try
            {
                var storageAccountName = Environment.GetEnvironmentVariable("DATA_LAKE_STORAGE_ACCOUNT");
                if (string.IsNullOrEmpty(storageAccountName))
                {
                    return new BadRequestObjectResult("Storage account configuration not found.");
                }

                // Validate container name
                if (!IsValidContainer(container))
                {
                    return new BadRequestObjectResult("Invalid container name. Valid containers: raw, processed, curated");
                }

                // Use managed identity to authenticate
                var credential = new DefaultAzureCredential();
                var dataLakeServiceClient = new DataLakeServiceClient(
                    new Uri($"https://{storageAccountName}.dfs.core.windows.net"), 
                    credential);

                var fileSystemClient = dataLakeServiceClient.GetFileSystemClient(container);
                var files = new List<object>();

                await foreach (var pathItem in fileSystemClient.GetPathsAsync())
                {
                    files.Add(new
                    {
                        Name = pathItem.Name,
                        IsDirectory = pathItem.IsDirectory,
                        LastModified = pathItem.LastModified,
                        ContentLength = pathItem.ContentLength
                    });
                }

                log.LogInformation($"Successfully listed {files.Count} items in container: {container}");

                return new OkObjectResult(new
                {
                    Container = container,
                    Files = files,
                    Count = files.Count,
                    Timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                log.LogError(ex, $"Failed to list files in container: {container}");
                return new ObjectResult(new { Error = ex.Message }) { StatusCode = 500 };
            }
        }

        [FunctionName("DownloadFromDataLake")]
        public static async Task<IActionResult> DownloadFile(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = "datalake/download/{container}/{fileName}")] HttpRequest req,
            string container,
            string fileName,
            ILogger log)
        {
            log.LogInformation($"Download request for file: {fileName} from container: {container}");

            try
            {
                var storageAccountName = Environment.GetEnvironmentVariable("DATA_LAKE_STORAGE_ACCOUNT");
                if (string.IsNullOrEmpty(storageAccountName))
                {
                    return new BadRequestObjectResult("Storage account configuration not found.");
                }

                // Validate container name
                if (!IsValidContainer(container))
                {
                    return new BadRequestObjectResult("Invalid container name. Valid containers: raw, processed, curated");
                }

                // Use managed identity to authenticate
                var credential = new DefaultAzureCredential();
                var dataLakeServiceClient = new DataLakeServiceClient(
                    new Uri($"https://{storageAccountName}.dfs.core.windows.net"), 
                    credential);

                var fileSystemClient = dataLakeServiceClient.GetFileSystemClient(container);
                var fileClient = fileSystemClient.GetFileClient(fileName);

                // Check if file exists
                var exists = await fileClient.ExistsAsync();
                if (!exists.Value)
                {
                    return new NotFoundObjectResult($"File {fileName} not found in container {container}");
                }

                // Download the file
                var response = await fileClient.ReadAsync();
                using var reader = new StreamReader(response.Value.Content);
                var content = await reader.ReadToEndAsync();

                log.LogInformation($"Successfully downloaded file: {fileName} from container: {container}");

                return new OkObjectResult(new
                {
                    Container = container,
                    FileName = fileName,
                    Content = content,
                    Timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                log.LogError(ex, $"Failed to download file: {fileName}");
                return new ObjectResult(new { Error = ex.Message }) { StatusCode = 500 };
            }
        }

        private static bool IsValidContainer(string container)
        {
            var validContainers = new[] { "raw", "processed", "curated" };
            return validContainers.Contains(container.ToLowerInvariant());
        }
    }
}
