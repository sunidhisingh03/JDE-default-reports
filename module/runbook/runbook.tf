## create runbooks
resource "azurerm_automation_runbook" "runbook" {
  name                    = var.runbook_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  log_verbose             = true
  log_progress            = true
  runbook_type            = "PowerShell74"
  content                 = templatefile(var.script_path, {})
  
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

## Create Schedule (Dynamic Frequency)
resource "azurerm_automation_schedule" "schedule" {
  name                    = var.schedule_name
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  frequency               = var.frequency       
  interval                = var.interval        
  timezone                = "Asia/Kolkata"
  start_time              = var.start_time      
  description             = "${var.frequency}ly runbook execution"
}

## Link Runbook to Schedule
resource "azurerm_automation_job_schedule" "job_schedule" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  runbook_name            = azurerm_automation_runbook.runbook.name
  schedule_name           = azurerm_automation_schedule.schedule.name
}



