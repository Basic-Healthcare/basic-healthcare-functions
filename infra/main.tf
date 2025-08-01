# Basic Healthcare Content Lake Infrastructure
# This configuration creates a data lake for AI purposes with Azure Functions

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Data sources for current client configuration
data "azurerm_client_config" "current" {}

# Resource naming using azurecaf
resource "azurecaf_name" "resource_group" {
  name          = var.environment_name
  resource_type = "azurerm_resource_group"
  suffixes      = [var.location]
}

resource "azurecaf_name" "storage_account" {
  name          = var.environment_name
  resource_type = "azurerm_storage_account"
  suffixes      = [var.location]
}

resource "azurecaf_name" "function_app" {
  name          = var.environment_name
  resource_type = "azurerm_function_app"
  suffixes      = [var.location]
}

resource "azurecaf_name" "app_service_plan" {
  name          = var.environment_name
  resource_type = "azurerm_app_service_plan"
  suffixes      = [var.location]
}

resource "azurecaf_name" "application_insights" {
  name          = var.environment_name
  resource_type = "azurerm_application_insights"
  suffixes      = [var.location]
}

resource "azurecaf_name" "log_analytics" {
  name          = var.environment_name
  resource_type = "azurerm_log_analytics_workspace"
  suffixes      = [var.location]
}

resource "azurecaf_name" "managed_identity" {
  name          = var.environment_name
  resource_type = "azurerm_user_assigned_identity"
  suffixes      = [var.location]
}

resource "azurecaf_name" "aks_cluster" {
  name          = var.environment_name
  resource_type = "azurerm_kubernetes_cluster"
  suffixes      = [var.location]
}

resource "azurecaf_name" "container_registry" {
  name          = var.environment_name
  resource_type = "azurerm_container_registry"
  suffixes      = [var.location]
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = azurecaf_name.resource_group.result
  location = var.location

  tags = {
    environment    = var.environment_name
    project        = "basic-healthcare"
    "azd-env-name" = var.environment_name
  }
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "main" {
  name                = azurecaf_name.managed_identity.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    environment = var.environment_name
    project     = "basic-healthcare"
  }
}

# Data Lake Storage Account (Gen2)
resource "azurerm_storage_account" "data_lake" {
  name                     = azurecaf_name.storage_account.result
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true # Enable hierarchical namespace for Data Lake Gen2
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  # Network access rules
  network_rules {
    default_action = "Allow" # In production, consider "Deny" with specific allow rules
  }

  tags = {
    environment = var.environment_name
    project     = "basic-healthcare"
  }
}

# Storage containers for different data zones
resource "azurerm_storage_data_lake_gen2_filesystem" "raw" {
  name               = "raw"
  storage_account_id = azurerm_storage_account.data_lake.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "processed" {
  name               = "processed"
  storage_account_id = azurerm_storage_account.data_lake.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "curated" {
  name               = "curated"
  storage_account_id = azurerm_storage_account.data_lake.id
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = azurecaf_name.log_analytics.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = var.environment_name
    project     = "basic-healthcare"
  }
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = azurecaf_name.application_insights.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = {
    environment = var.environment_name
    project     = "basic-healthcare"
  }
}

# App Service Plan for Azure Functions
resource "azurerm_service_plan" "main" {
  name                = azurecaf_name.app_service_plan.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan

  tags = {
    environment = var.environment_name
    project     = "basic-healthcare"
  }
}

# Function App
resource "azurerm_linux_function_app" "main" {
  name                = azurecaf_name.function_app.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  storage_account_name       = azurerm_storage_account.data_lake.name
  storage_account_access_key = azurerm_storage_account.data_lake.primary_access_key

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  site_config {
    application_insights_key               = azurerm_application_insights.main.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.main.connection_string
    
    application_stack {
      python_version = "3.11"
    }

    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"      = "python"
    "WEBSITE_RUN_FROM_PACKAGE"      = "1"
    "STORAGE_ACCOUNT_URL"           = "https://${azurerm_storage_account.data_lake.name}.blob.core.windows.net"
    "DATA_LAKE_STORAGE_ACCOUNT"     = azurerm_storage_account.data_lake.name
    "DATA_LAKE_RAW_CONTAINER"       = azurerm_storage_data_lake_gen2_filesystem.raw.name
    "DATA_LAKE_PROCESSED_CONTAINER" = azurerm_storage_data_lake_gen2_filesystem.processed.name
    "DATA_LAKE_CURATED_CONTAINER"   = azurerm_storage_data_lake_gen2_filesystem.curated.name
    "AZURE_CLIENT_ID"               = azurerm_user_assigned_identity.main.client_id
  }

  tags = {
    environment = var.environment_name
    project     = "basic-healthcare"
  }
}

# Role assignments for Managed Identity
# NOTE: Temporarily commented out due to service principal permissions
# These will need to be added manually or via a service principal with User Access Administrator role

# resource "azurerm_role_assignment" "storage_blob_data_contributor" {
#   scope                = azurerm_storage_account.data_lake.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_user_assigned_identity.main.principal_id
# }

# resource "azurerm_role_assignment" "storage_blob_data_owner" {
#   scope                = azurerm_storage_account.data_lake.id
#   role_definition_name = "Storage Blob Data Owner"
#   principal_id         = azurerm_user_assigned_identity.main.principal_id
# }

# resource "azurerm_role_assignment" "storage_queue_data_contributor" {
#   scope                = azurerm_storage_account.data_lake.id
#   role_definition_name = "Storage Queue Data Contributor"
#   principal_id         = azurerm_user_assigned_identity.main.principal_id
# }

# resource "azurerm_role_assignment" "storage_table_data_contributor" {
#   scope                = azurerm_storage_account.data_lake.id
#   role_definition_name = "Storage Table Data Contributor"
#   principal_id         = azurerm_user_assigned_identity.main.principal_id
# }

# resource "azurerm_role_assignment" "monitoring_metrics_publisher" {
#   scope                = azurerm_resource_group.main.id
#   role_definition_name = "Monitoring Metrics Publisher"
#   principal_id         = azurerm_user_assigned_identity.main.principal_id
# }

# Diagnostic settings for Function App
resource "azurerm_monitor_diagnostic_setting" "function_app" {
  name                       = "function-app-diagnostics"
  target_resource_id         = azurerm_linux_function_app.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Container Registry for AKS
resource "azurerm_container_registry" "main" {
  name                = azurecaf_name.container_registry.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    environment = var.environment_name
    project     = "basic-healthcare"
  }
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = azurecaf_name.aks_cluster.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.environment_name}-aks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment_name
    project     = "basic-healthcare"
  }
}

# Grant AKS pull access to Container Registry
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# Local exec to build and push Docker image, then deploy to AKS
resource "null_resource" "aks_deployment" {
  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_container_registry.main,
    azurerm_role_assignment.aks_acr_pull
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Build and push Docker image
      docker build -t ${azurerm_container_registry.main.login_server}/basic-healthcare-app:latest ../aks-app
      docker login ${azurerm_container_registry.main.login_server} -u ${azurerm_container_registry.main.admin_username} -p ${azurerm_container_registry.main.admin_password}
      docker push ${azurerm_container_registry.main.login_server}/basic-healthcare-app:latest
      
      # Get AKS credentials
      az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name} --overwrite-existing
      
      # Update deployment with correct image
      sed 's|\${CONTAINER_REGISTRY}|${azurerm_container_registry.main.login_server}|g' ../k8s/deployment.yaml > /tmp/deployment.yaml
      
      # Deploy to AKS
      kubectl apply -f /tmp/deployment.yaml
      kubectl apply -f ../k8s/service.yaml
      
      # Wait for deployment
      kubectl rollout status deployment/basic-healthcare-app --timeout=300s
    EOT
  }

  triggers = {
    cluster_name = azurerm_kubernetes_cluster.main.name
    registry_url = azurerm_container_registry.main.login_server
    # Trigger on file changes
    app_content = filemd5("../aks-app/app.py")
    dockerfile_content = filemd5("../aks-app/Dockerfile")
  }
}
