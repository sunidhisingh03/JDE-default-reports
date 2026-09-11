variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "automation_account_name" {
  type = string
}

variable "sku" {
  type = string
  default = "Basic"
}

variable "tags" {
  type = map(string)
}