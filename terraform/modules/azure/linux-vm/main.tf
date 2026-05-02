# Optional: dedicated VNet and Subnet (no public gateway)
resource "azurerm_virtual_network" "vm" {
  count               = var.create_network ? 1 : 0
  name                = "${var.vm_name}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "vm" {
  count                = var.create_network ? 1 : 0
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vm[0].name
  address_prefixes     = var.subnet_address_prefixes
}

# Public IP (only when enable_public_ip)
resource "azurerm_public_ip" "vm" {
  count               = var.enable_public_ip ? 1 : 0
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# NSG: SSH from VNet; optionally from Internet when public IP is enabled
resource "azurerm_network_security_group" "vm" {
  name                = "${var.vm_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowSSHFromVNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.enable_public_ip ? [1] : []
    content {
      name                       = "AllowSSHFromInternet"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.ssh_source_address_prefix
      destination_address_prefix = "*"
    }
  }
}

locals {
  subnet_id = var.create_network ? azurerm_subnet.vm[0].id : var.subnet_id
  # Azure VM requires a one-line OpenSSH key; removes CR/BOM and accidental multiline input.
  admin_ssh_public_key_normalized = trimspace(
    split("\n", replace(trimspace(var.admin_ssh_public_key), "\r", ""))[0]
  )
}

# Network interface (with optional public IP)
resource "azurerm_network_interface" "vm" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.vm[0].id : null
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# Ubuntu Linux VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = (var.disable_password_authentication ? null : (var.admin_password != "" ? var.admin_password : null))
  disable_password_authentication = var.disable_password_authentication
  tags                            = var.tags
  network_interface_ids           = [azurerm_network_interface.vm.id]

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = var.ubuntu_sku
    version   = "latest"
  }

  dynamic "admin_ssh_key" {
    for_each = var.disable_password_authentication && local.admin_ssh_public_key_normalized != "" ? [1] : []
    content {
      username   = var.admin_username
      public_key = local.admin_ssh_public_key_normalized
    }
  }

  custom_data = (
    var.custom_data != null && trimspace(var.custom_data) != ""
  ) ? base64encode(var.custom_data) : null

  lifecycle {
    precondition {
      condition     = var.create_network || (var.subnet_id != null && var.subnet_id != "")
      error_message = "When create_network is false, subnet_id must be set to an existing subnet resource ID."
    }
    precondition {
      condition     = !var.disable_password_authentication || local.admin_ssh_public_key_normalized != ""
      error_message = "When disable_password_authentication is true, admin_ssh_public_key must be non-empty (OpenSSH one-line, e.g. ssh-ed25519 AAAA...)."
    }
  }
}
