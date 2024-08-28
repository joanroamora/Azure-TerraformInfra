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
  zones = ["${(count.index % 3 + 1)}"]

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
  count               = var.vm_count
  name                = "backend-nic-${count.index}"
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
  count               = var.vm_count
  name                = "backend-vm-${count.index}"
  location            = var.location
  resource_group_name = var.resourceGroup
  network_interface_ids = [azurerm_network_interface.backend[count.index].id]  # Acceso por índice
  vm_size             = var.vm_size 
  zones               = ["${(count.index % 3 + 1)}"]  # Distribuir entre las zonas 1, 2, y 3

  os_profile {
    computer_name  = "backend-vm-${count.index}"
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
    name              = "backend-osdisk-${count.index}"
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
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 4
  read_scale     = true
  sku_name       = "S0"
  zone_redundant = true  # Activa la redundancia de zona
  enclave_type   = "VBS"

  tags = {
    environment = "production"
  }

  lifecycle {
    prevent_destroy = true
  }
}

#SECOND AVAILABILITY REGION
resource "azurerm_virtual_machine" "secondary_frontend" {
  count               = var.vm_count
  name                = "secondary-frontend-vm-${count.index}"
  location            = var.secondary_location
  resource_group_name = var.resourceGroup
  network_interface_ids = [azurerm_network_interface.secondary_frontend[count.index].id]
  vm_size             = var.vm_size
  zones               = ["${count.index % 3 + 1}"]  # Distribuir entre las zonas 1, 2 y 3 en la región secundaria

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

resource "azurerm_network_interface" "secondary_frontend" {
  count               = var.vm_count
  name                = "secondary-frontend-nic-${count.index}"
  location            = var.secondary_location
  resource_group_name = var.resourceGroup

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.secondary_public.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_lb.secondary_frontend_lb,
    azurerm_subnet.secondary_public,
    azurerm_network_security_group.frontend_sg  # Si usas el mismo SG o uno específico para la región secundaria
  ]
}

resource "azurerm_network_interface" "secondary_backend" {
  count               = var.vm_count
  name                = "secondary-backend-nic-${count.index}"
  location            = var.secondary_location
  resource_group_name = var.resourceGroup

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.secondary_private.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_lb.secondary_backend_lb,
    azurerm_subnet.secondary_private,  
    azurerm_network_security_group.backend_sg
  ]
}


resource "azurerm_virtual_machine" "secondary_backend" {
  count               = var.vm_count
  name                = "secondary-backend-vm-${count.index}"
  location            = var.secondary_location
  resource_group_name = var.resourceGroup
  network_interface_ids = [azurerm_network_interface.secondary_backend[count.index].id]
  vm_size             = var.vm_size 
  zones = ["${(count.index % 3 + 1)}"]  # Distribuir entre las zonas 1, 2, y 3 en la región secundaria

  os_profile {
    computer_name  = "secondary-backend-vm-${count.index}"
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
    name              = "secondary-backend-osdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  tags = {
    environment = "backend"
  }

  depends_on = [
    azurerm_network_interface.secondary_backend
  ]
}

resource "azurerm_mssql_server" "secondary_sqlserver" {
  name                         = "${var.sql_server_name}-secondary"
  resource_group_name          = var.resourceGroup
  location                     = var.secondary_location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  depends_on = [
    azurerm_network_security_group.sql_sg,
    azurerm_subnet.secondary_private_db
  ]
}

resource "azurerm_mssql_database" "secondary_sqldatabase" {
  name           = "${var.sql_database_name}-secondary"
  server_id      = azurerm_mssql_server.secondary_sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 4
  read_scale     = true
  sku_name       = "S0"
  zone_redundant = true  # Activa la redundancia de zona
  enclave_type   = "VBS"

  tags = {
    environment = "production"
  }

  lifecycle {
    prevent_destroy = true
  }
}