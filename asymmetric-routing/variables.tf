variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used in Azure resource names."
  type        = string
  default     = "dns-troubleshooting"
}

variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "spaincentral"
}

variable "vm_admin_username" {
  description = "Shared administrator username for both Windows VMs."
  type        = string
  default     = "azureuser"
}

variable "vm_admin_password" {
  description = "Shared administrator password for both Windows VMs."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.vm_admin_password) >= 12
    error_message = "The VM administrator password must contain at least 12 characters."
  }
}

