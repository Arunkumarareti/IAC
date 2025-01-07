terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.14.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "123efc84-f3ee-4390-b25c-70cefb0ed75c"
}

# Resource Group
resource "azurerm_resource_group" "Task" {
  name     = "Task-secure-3tier-rg"
  location = "eastus"
}

# Virtual Network
resource "azurerm_virtual_network" "Task" {
  name                = "Task-3tier-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.Task.location
  resource_group_name = azurerm_resource_group.Task.name
}

# Subnets
resource "azurerm_subnet" "frontend" {
  name                 = "frontend-subnet"
  resource_group_name  = azurerm_resource_group.Task.name
  virtual_network_name = azurerm_virtual_network.Task.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_resource_group.Task.name
  virtual_network_name = azurerm_virtual_network.Task.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.Task.name
  virtual_network_name = azurerm_virtual_network.Task.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Network Security Groups (NSGs)
# Frontend NSG
resource "azurerm_network_security_group" "frontend" {
  name                = "frontend-nsg"
  location            = azurerm_resource_group.Task.location
  resource_group_name = azurerm_resource_group.Task.name

  security_rule {
    name                       = "Allow-HTTP-HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefixes    = ["217.42.13.186/32"] # Replace ISP IP 
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

# Backend NSG
resource "azurerm_network_security_group" "backend" {
  name                = "backend-nsg"
  location            = azurerm_resource_group.Task.location
  resource_group_name = azurerm_resource_group.Task.name

  security_rule {
    name                       = "Allow-Frontend-Traffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "10.0.1.0/24" # Frontend pubilc subnet allowed
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

# Database NSG
resource "azurerm_network_security_group" "database" {
  name                = "database-nsg"
  location            = azurerm_resource_group.Task.location
  resource_group_name = azurerm_resource_group.Task.name

  security_rule {
    name                       = "Allow-Backend-Traffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "10.0.2.0/24" # Backend subnet only allowed
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "frontend" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend.id
}

resource "azurerm_subnet_network_security_group_association" "backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.backend.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}

# Public IP for Frontend
resource "azurerm_public_ip" "frontend" {
  name                = "frontend-public-ip"
  location            = azurerm_resource_group.Task.location
  resource_group_name = azurerm_resource_group.Task.name
  allocation_method   = "Static"
}



