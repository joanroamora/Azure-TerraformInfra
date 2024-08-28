resource "azurerm_network_interface" "frontend" {
  count               = var.vm_count
  name                = "frontend-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resourceGroup

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_lb.frontend,
    azurerm_subnet.public,
    azurerm_network_security_group.frontend_sg
  ]
}

resource "azurerm_virtual_machine" "frontend" {
  count               = var.vm_count
  name                = "frontend-vm-${count.index}"
  location            = var.location
  resource_group_name = var.resourceGroup
  network_interface_ids = [azurerm_network_interface.frontend[count.index].id]
  vm_size             = var.vm_size

  os_profile {
    computer_name  = "frontend-vm-${count.index}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {}

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "frontend-osdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  tags = {
    environment = "frontend"
  }

  depends_on = [
    azurerm_network_interface.frontend
  ]
}

resource "azurerm_network_interface" "backend" {
  name                = "backend-nic"
  location            = var.location
  resource_group_name = var.resourceGroup

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private1.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_network_security_group.backend_sg,
    azurerm_subnet.private1
  ]
}

resource "azurerm_virtual_machine" "backend" {
  name                = "backend-vm"
  location            = var.location
  resource_group_name = var.resourceGroup
  network_interface_ids = [azurerm_network_interface.backend.id]
  vm_size             = var.backend_vm_size

  os_profile {
    computer_name  = "backend-vm"
    admin_username = var.backend_admin_username
    admin_password = var.backend_admin_password
  }

  os_profile_windows_config {}

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "backend-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  tags = {
    environment = "backend"
  }

  depends_on = [
    azurerm_network_interface.backend
  ]
}

resource "azurerm_mssql_server" "sqlserver" {
  name                         = var.sql_server_name
  resource_group_name          = var.resourceGroup
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  depends_on = [
    azurerm_network_security_group.sql_sg,
    azurerm_subnet.private2
  ]
}

resource "azurerm_mssql_database" "sqldatabase" {
  name                 = var.sql_database_name
  server_id            = azurerm_mssql_server.sqlserver.id
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  license_type         = "LicenseIncluded"
  max_size_gb          = 2
  read_scale           = false
  sku_name             = "Basic"
  enclave_type         = "VBS"
  
  tags = {
    environment = "production"
  }
  
  lifecycle {
    prevent_destroy = false
  }
}