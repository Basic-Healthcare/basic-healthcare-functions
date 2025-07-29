output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "RESOURCE_GROUP_ID" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "function_app_name" {
  description = "The name of the function app"
  value       = azurerm_linux_function_app.main.name
}

output "storage_account_name" {
  description = "The name of the data lake storage account"
  value       = azurerm_storage_account.data_lake.name
}

output "application_insights_instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "function_app_url" {
  description = "The URL of the function app"
  value       = "https://${azurerm_linux_function_app.main.name}.azurewebsites.net"
}

output "data_lake_raw_container" {
  description = "The name of the raw data container"
  value       = azurerm_storage_data_lake_gen2_filesystem.raw.name
}

output "data_lake_processed_container" {
  description = "The name of the processed data container"
  value       = azurerm_storage_data_lake_gen2_filesystem.processed.name
}

output "data_lake_curated_container" {
  description = "The name of the curated data container"
  value       = azurerm_storage_data_lake_gen2_filesystem.curated.name
}

output "managed_identity_client_id" {
  description = "The client ID of the managed identity"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "storage_account_url" {
  description = "The URL of the storage account"
  value       = "https://${azurerm_storage_account.data_lake.name}.blob.core.windows.net"
}

output "function_app_publish_profile" {
  description = "The function app publish profile for deployment"
  value       = azurerm_linux_function_app.main.name
  sensitive   = true
}
