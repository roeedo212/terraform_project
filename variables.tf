variable "location" {
  type    = string
  default = "westeurope"
}

variable "resource_group_name" {
  type    = string
  default = "rg-weightTracker"
}

variable "vnet_name" {
  type    = string
  default = "vnet-weightTracker-easteu"
}

variable "subnet_flask_name" {
  type    = string
  default = "snet-web-westeu"
}

variable "subnet_db_name" {
  type    = string
  default = "snet-data-westeu"
}

variable "my_ip_address" {
  type    = string
  default = "194.90.46.191"
}

variable "flask_vm_name" {
  type = string
  default = "vm-flask"
}

variable "db_vm_name" {
  type = string
  default = "vm-postgressql"
}

variable "db_password" {
  type = string
  description = "password for data base user"
}
