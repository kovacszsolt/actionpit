variable "resource_group_name" {
  description = "Resource group for the VNet, subnets, and private DNS zone."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name."
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network (e.g. [\"10.200.0.0/16\"])."
  type        = list(string)
}

variable "cae_subnet_name" {
  description = "Subnet name delegated to Microsoft.App/environments (Container Apps)."
  type        = string
}

variable "cae_subnet_address_prefixes" {
  description = "CAE infrastructure subnet CIDR(s). Use at least /21 where required by Azure for Container Apps."
  type        = list(string)
}

variable "postgresql_subnet_name" {
  description = "Subnet name delegated to Microsoft.DBforPostgreSQL/flexibleServers."
  type        = string
}

variable "postgresql_subnet_address_prefixes" {
  description = "PostgreSQL Flexible Server delegated subnet CIDR(s); must not overlap CAE subnet."
  type        = list(string)
}

variable "private_dns_zone_name" {
  description = "Private DNS zone for PostgreSQL Flexible Server VNet integration (normally privatelink.postgres.database.azure.com)."
  type        = string
  default     = "privatelink.postgres.database.azure.com"
}

variable "private_dns_zone_link_name" {
  description = "Name of the VNet link on the private DNS zone."
  type        = string
}

variable "jump_subnet_name" {
  description = "Name of the optional non-delegated subnet for a jump VM. Required when jump_subnet_address_prefixes is non-empty."
  type        = string
  default     = ""
}

variable "jump_subnet_address_prefixes" {
  description = "CIDR(s) for the jump subnet; must not overlap CAE or PostgreSQL subnets. Empty list = do not create jump subnet."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags for VNet and DNS zone."
  type        = map(string)
  default     = {}
}
