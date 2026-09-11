terraform {
  backend "azurerm" {
      resource_group_name  = "tw-rg"
      storage_account_name = "twstg02"
      container_name       = "jde-test"
      key                  = "FinOpsReports/terraform.tfstate"
      use_azuread_auth     = true      # REQUIRED
  }
}