# Minimal test configuration to verify Terraform deployment works
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Just create a simple resource group for testing
resource "azurerm_resource_group" "test" {
  name     = "rg-test-minimal-eastus"
  location = "East US"

  tags = {
    environment = "test"
    purpose     = "minimal-test"
  }
}

# Simple output
output "test_resource_group_name" {
  value = azurerm_resource_group.test.name
}

output "test_resource_group_id" {
  value = azurerm_resource_group.test.id
}
