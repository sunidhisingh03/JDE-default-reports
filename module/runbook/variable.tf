
variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "automation_account_name" {
  type = string
}

variable "runbook_name" {
  type = string
}

variable "script_path" {
  type = string
}

variable "schedule_name" {
  type = string
}

variable "start_time" {
  type = string
}


variable "frequency" {
  type    = string
  default = "Month" # Can be "Day" or "Month"
}

variable "interval" {
  type    = number
  default = 1
}

variable "tags" {
  type = map(string)
}

# variable "runtime_environment_id" {
#   description = "PowerShell 7.4 Runtime Environment ID"
#   type        = string
# }