variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "terraform_principal_id" {
  description = "Object ID of the identity running Terraform — granted Key Vault Administrator so it can write secrets."
  type        = string
}

variable "secrets" {
  description = "Map of secret name -> value to write into the vault."
  type        = map(string)
  sensitive   = true
}
