# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.35.0"

  subscription_id = "SUBSCRIPTION_ID"
  tenant_id       = "TENANT_ID"
  client_id       = "CLIENT_ID"
  client_secret   = "SECRET"
}

provider "azuread" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=0.6.0"

  subscription_id = "SUBSCRIPTION_ID"
  tenant_id       = "TENANT_ID"
  client_id       = "CLIENT_ID"
  client_secret   = "SECRET"
}

resource "azurerm_resource_group" "test" {
  name     = "testResourceGroup1"
  location = "East US"
}

data "azuread_user" "example" {
  user_principal_name = "userid@domain.com"
}

resource "azurerm_role_assignment" "test" {
  scope                = "/subscriptions/SUBSCRIPTION_ID/resourceGroups/testResourceGroup1"
  role_definition_name = "Reader"
  principal_id         = "${data.azuread_user.example.id}"
}
