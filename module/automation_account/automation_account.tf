resource "azurerm_automation_account" "account" {
  name                = var.automation_account_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
  public_network_access_enabled = false
}