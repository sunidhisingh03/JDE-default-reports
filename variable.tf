variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "automation_account_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

# variable "runtime_environment_id" {
#   description = "PowerShell 7.4 Runtime Environment ID"
#   type        = string
# }