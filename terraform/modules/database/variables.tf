variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "administrator_login" {
  type    = string
  default = "strapi_admin"
}

variable "administrator_password" {
  type      = string
  sensitive = true
}

variable "database_name" {
  type    = string
  default = "strapi"
}

