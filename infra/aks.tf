# AKS Cluster Configuration
resource "azurerm_kubernetes_cluster" "main" {
  name                = azurecaf_name.aks_cluster.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "basic-healthcare-aks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
    
    # Enable auto-scaling for cost optimization
    enable_auto_scaling = true
    min_count          = 1
    max_count          = 3
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment    = var.environment_name
    project        = "basic-healthcare"
    "azd-env-name" = var.environment_name
  }
}

# Container Registry for storing images
resource "azurerm_container_registry" "main" {
  name                = azurecaf_name.container_registry.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = {
    environment    = var.environment_name
    project        = "basic-healthcare"
    "azd-env-name" = var.environment_name
  }
}

# Role assignment to allow AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                           = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}
