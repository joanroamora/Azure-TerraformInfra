resource "azurerm_virtual_network" "main" {
  name                = "main-vpc"
  address_space       = [var.vpc_cidr]
  location            = var.location
  resource_group_name = var.resourceGroup
}

resource "azurerm_subnet" "public" {
  name                 = "public-subnet"
  resource_group_name  = var.resourceGroup
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_cidr]
}

resource "azurerm_subnet" "private1" {
  name                 = "private-subnet-1"
  resource_group_name  = var.resourceGroup
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet1_cidr]
}

resource "azurerm_subnet" "private2" {
  name                 = "private-subnet-2"
  resource_group_name  = var.resourceGroup
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet2_cidr]
}

resource "azurerm_public_ip" "frontend_lb" {
  name                = var.frontend_lb_public_ip_name
  location            = var.location
  resource_group_name = var.resourceGroup
  allocation_method   = "Static"
}

resource "azurerm_lb" "frontend" {
  name                = var.frontend_lb_name
  location            = var.location
  resource_group_name = var.resourceGroup
  #sku                 = "Basic"

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.frontend_lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "frontend" {
  name            = "frontend-backend-pool"
  loadbalancer_id = azurerm_lb.frontend.id
}


resource "azurerm_lb_rule" "frontend" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.frontend.id
  frontend_ip_configuration_name = azurerm_lb.frontend.frontend_ip_configuration[0].name
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.frontend.id]
}

resource "azurerm_network_security_group" "frontend_sg" {
  name                = var.frontend_security_group_name
  location            = var.location
  resource_group_name = var.resourceGroup

  security_rule {
    name                       = "allow-http"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "backend_sg" {
  name                = var.backend_security_group_name
  location            = var.location
  resource_group_name = var.resourceGroup

  security_rule {
    name                       = "allow-frontend"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6000"
    source_address_prefix      = "10.0.4.0/22"  # Assuming frontend is within this range
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-mysql-outbound"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.8.0/22"
  }
}

resource "azurerm_network_security_group" "sql_sg" {
  name                = var.sql_security_group_name
  location            = var.location
  resource_group_name = var.resourceGroup

  security_rule {
    name                       = "allow-private1"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"  # Default SQL Server port
    source_address_prefix      = var.private_subnet1_cidr  # CIDR block for private1 subnet
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "private2_sg_assoc" {
  subnet_id                 = azurerm_subnet.private2.id
  network_security_group_id = azurerm_network_security_group.sql_sg.id
}

#SECOND AVAILABILITY REGION
resource "azurerm_virtual_network" "secondary_vnet" {
  name                = "secondary-backend-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = var.secondary_location
  resource_group_name = var.resourceGroup
}

resource "azurerm_subnet" "secondary_private" {
  name                 = "secondary-private-subnet"
  resource_group_name  = var.resourceGroup
  virtual_network_name = azurerm_virtual_network.secondary_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "secondary_public" {
  name                 = "secondary-public-subnet"
  resource_group_name  = var.resourceGroup
  virtual_network_name = azurerm_virtual_network.secondary_vnet.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_lb" "secondary_frontend_lb" {
  name                = "secondary-frontend-lb"
  location            = var.secondary_location
  resource_group_name = var.resourceGroup
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "secondary-frontend-config"
    public_ip_address_id = azurerm_public_ip.secondary_lb.id
  }
}

resource "azurerm_public_ip" "secondary_lb" {
  name                = "secondary-frontend-pip"
  location            = var.secondary_location
  resource_group_name = var.resourceGroup
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "secondary_backend_lb" {
  name                = "secondary-backend-lb"
  location            = var.secondary_location
  resource_group_name = var.resourceGroup
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "secondary-backend-config"
    public_ip_address_id = azurerm_public_ip.secondary_lb.id
  }
}

resource "azurerm_virtual_network" "secondary_vnet_db" {
  name                = "secondary-db-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = var.secondary_location
  resource_group_name = var.resourceGroup
}

resource "azurerm_subnet" "secondary_private_db" {
  name                 = "secondary-private-db-subnet"
  resource_group_name  = var.resourceGroup
  virtual_network_name = azurerm_virtual_network.secondary_vnet_db.name
  address_prefixes     = ["10.1.2.0/24"]
}
