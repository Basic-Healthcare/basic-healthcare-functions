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
    min_count           = 1
    max_count           = 3
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
  admin_enabled       = true

  tags = {
    environment    = var.environment_name
    project        = "basic-healthcare"
    "azd-env-name" = var.environment_name
  }
}

# Role assignment to allow AKS to pull from ACR
# Temporarily commented out - role assignment created manually
# resource "azurerm_role_assignment" "aks_acr_pull" {
#   principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
#   role_definition_name             = "AcrPull"
#   scope                            = azurerm_container_registry.main.id
#   skip_service_principal_aad_check = true
# }

# Local exec to build and push Docker image, then deploy to AKS
resource "null_resource" "aks_deployment" {
  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_container_registry.main
    # Removed azurerm_role_assignment.aks_acr_pull dependency - role assignment created manually
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
      sed 's|$${CONTAINER_REGISTRY}|${azurerm_container_registry.main.login_server}|g' ../k8s/deployment.yaml > /tmp/deployment.yaml
      
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
    app_content        = filemd5("../aks-app/app.py")
    dockerfile_content = filemd5("../aks-app/Dockerfile")
  }
}
