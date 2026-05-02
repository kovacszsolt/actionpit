variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vm_name" {
  description = "Name of the Linux virtual machine"
  type        = string
}

variable "vm_size" {
  description = "VM size (e.g. Standard_B2s)"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "admin_ssh_public_key" {
  description = "SSH public key for admin_username (recommended). Leave empty to use admin_password."
  type        = string
  default     = ""
  sensitive   = true
}

variable "admin_password" {
  description = "Admin password (use only if admin_ssh_public_key is not set). Must meet Azure complexity: 3 of 4 (lowercase, uppercase, digit, special char except _)."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition = (
      var.admin_password == "" ||
      (length(var.admin_password) >= 8 &&
        ((can(regex("[a-z]", var.admin_password)) ? 1 : 0) +
          (can(regex("[A-Z]", var.admin_password)) ? 1 : 0) +
          (can(regex("[0-9]", var.admin_password)) ? 1 : 0) +
      (can(regex("[^a-zA-Z0-9_]", var.admin_password)) ? 1 : 0)) >= 3)
    )
    error_message = "admin_password must be at least 8 characters and fulfill 3 of 4: lowercase, uppercase, digit, special character (other than _). Example: MySecurePass1!"
  }
}

variable "vnet_address_space" {
  description = "Address space for the VNet (used only when create_network = true)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Subnet address prefix (used only when create_network = true)"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "create_network" {
  description = "Create dedicated VNet and Subnet for the VM. If false, subnet_id must be provided."
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Existing subnet ID (required when create_network = false)"
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "ubuntu_sku" {
  description = "Ubuntu image SKU (e.g. 22_04-lts)"
  type        = string
  default     = "22_04-lts"
}

variable "disable_password_authentication" {
  description = "Disable password auth (true when SSH key is provided)"
  type        = bool
  default     = true
}

variable "enable_public_ip" {
  description = "Assign a public IP to the VM so it can be reached from the internet (e.g. SSH). If false, only private IP (Bastion/VPN)."
  type        = bool
  default     = false
}

variable "ssh_source_address_prefix" {
  description = "Inbound SSH (port 22) source when enable_public_ip is true. Use your public IPv4 /32 for least exposure; \"*\" allows any (not recommended for production)."
  type        = string
  default     = "*"
}

variable "custom_data" {
  description = "Optional first-boot script (cloud-init). Plain text (#cloud-config YAML or shell); stored base64 on the VM. Runs once on initial provisioning."
  type        = string
  default     = null
  nullable    = true
}
