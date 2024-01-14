terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.87.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Cria o grupo de recursos da Aplicação da pelada
resource "azurerm_resource_group" "rg-terraform" {
  name = var.rg_name
  location = var.rg_location
  tags = var.rg_tags
}

# Cria a conta do cosmosDB para a aplicação da pelada
resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "cosmosacct-${var.application_name}-001"
  resource_group_name = azurerm_resource_group.rg-terraform.name
  location            = azurerm_resource_group.rg-terraform.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    failover_priority = 0
    location          = azurerm_resource_group.rg-terraform.location
  }
}

# Cria a base de dados SQL para a aplicação da pelada
resource "azurerm_cosmosdb_sql_database" "cosmosdb" {
  name                = "cosmos-${var.application_name}-001"
  resource_group_name = azurerm_cosmosdb_account.cosmosdb.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
}

# Cria uma aplicação Azure Spring
resource "azurerm_spring_cloud_service" "rg-terraform" {
  name                = "${var.application_name}"
  resource_group_name = azurerm_resource_group.rg-terraform.name
  location            = azurerm_resource_group.rg-terraform.location
}

resource "azurerm_spring_cloud_app" "rg-terraform" {
  name                = "${var.application_name}-app"
  resource_group_name = azurerm_resource_group.rg-terraform.name
  service_name        = azurerm_spring_cloud_service.rg-terraform.name
  is_public           = true
  https_only          = true
}

resource "azurerm_spring_cloud_java_deployment" "rg-terraform" {
  name                = "default"
  spring_cloud_app_id = azurerm_spring_cloud_app.rg-terraform.id
  quota {
    cpu    = "2"
    memory = "4Gi"
  }
  instance_count      = 1
  jvm_options         = "-XX:+PrintGC"
  runtime_version     = "Java_17"

  environment_variables = {
    "spring.cloud.azure.cosmos.endpoint" : azurerm_cosmosdb_account.cosmosdb.endpoint
    "spring.cloud.azure.cosmos.key" : azurerm_cosmosdb_account.cosmosdb.primary_key
    "spring.cloud.azure.cosmos.database" : azurerm_cosmosdb_sql_database.cosmosdb.name
  }
}

resource "azurerm_spring_cloud_active_deployment" "rg-terraform" {
  spring_cloud_app_id = azurerm_spring_cloud_app.rg-terraform.id
  deployment_name     = azurerm_spring_cloud_java_deployment.rg-terraform.name
}

# Criar application insights
resource "azurerm_application_insights" "rg-terraform" {
  name                = "${var.application_name}-appinsights"
  location            = azurerm_resource_group.rg-terraform.location
  resource_group_name = azurerm_resource_group.rg-terraform.name
  application_type    = "web"
}
