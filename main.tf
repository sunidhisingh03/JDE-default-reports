module "automation_account" {
  source                  = "./module/automation_account"
  resource_group_name     = var.resource_group_name
  location                = var.location
  automation_account_name = var.automation_account_name
  tags                    = var.tags
}

# module "runbook1" {
#   source                  = "./module/runbook"
#   resource_group_name     = var.resource_group_name
#   location                = var.location
#   automation_account_name = var.automation_account_name
#   runbook_name            = "AllResources"
#   script_path             = "${path.module}/Scripts/all_resources_report.ps1"
#   schedule_name           = "schedule1"
#   start_time              = "2026-09-12T09:00:00+05:30"
#   frequency               = "Day"
#   interval                = 1
#   tags                    = var.tags
# }

# module "runbook2" {
#   source                  = "./module/runbook"
#   resource_group_name     = var.resource_group_name
#   location                = var.location
#   automation_account_name = var.automation_account_name
#   runbook_name            = "BackupReport"
#   script_path             = "${path.module}/Scripts/backup_report.ps1"
#   schedule_name           = "schedule2"
#   start_time              = "2026-09-12T09:40:00+05:30"
#   frequency               = "Month"
#   interval                = 1
#   tags                    = var.tags
# }

