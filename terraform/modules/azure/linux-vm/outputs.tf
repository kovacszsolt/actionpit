output "vm_id" {
  description = "ID of the Linux virtual machine"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.vm.private_ip_address
}

output "vm_public_ip" {
  description = "Public IP address of the VM (only when enable_public_ip = true)"
  value       = var.enable_public_ip ? azurerm_public_ip.vm[0].ip_address : null
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.vm.id
}

output "subnet_id" {
  description = "Subnet ID where the VM is deployed"
  value       = local.subnet_id
}

output "vnet_id" {
  description = "VNet ID (only set when create_network = true)"
  value       = var.create_network ? azurerm_virtual_network.vm[0].id : null
}
