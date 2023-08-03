provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnets
resource "azurerm_subnet" "subnet_flask" {
  name                 = var.subnet_flask_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]  # Update the attribute name to "address_prefixes"
}

resource "azurerm_subnet" "subnet_db" {
  name                 = var.subnet_db_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]  # Update the attribute name to "address_prefixes"
}
# NSG for Flask VM Subnet
resource "azurerm_network_security_group" "nsg_flask" {
  name                = "nsg-flask"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_web"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Flask Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_flask_association" {
  subnet_id                 = azurerm_subnet.subnet_flask.id
  network_security_group_id = azurerm_network_security_group.nsg_flask.id
}

# NSG for DB VM Subnet
resource "azurerm_network_security_group" "nsg_db" {
  name                = "nsg-db"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow_ssh_db"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_postgresql"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
}

# Associate NSG with DB Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_db_association" {
  subnet_id                 = azurerm_subnet.subnet_db.id
  network_security_group_id = azurerm_network_security_group.nsg_db.id
}

# Generate SSH Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
}

# Write Private Key to File
resource "local_file" "ssh_private_key" {
  filename = "C:/Users/Roee/.ssh/id_rsa"  # Replace with the desired path on your local machine
  content  = tls_private_key.ssh_key.private_key_pem
}

# Create Public IP for Flask VM
resource "azurerm_public_ip" "flask_vm_public_ip" {
  name                = "flask-vm-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Public IP for PostgreSQL VM
resource "azurerm_public_ip" "postgresql_vm_public_ip" {
  name                = "postgresql-vm-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Flask VM
resource "azurerm_linux_virtual_machine" "flask_vm" {
  name                = var.flask_vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_B2s_v2"
  admin_username      = "azureuser"
  admin_ssh_key {
    username   = "azureuser"
    # Use the generated private key for authentication
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  network_interface_ids = [azurerm_network_interface.flask_vm_nic.id]

  os_disk {
    name              = "flask-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-lts"
    version   = "latest"
  }
}

# Create PostgreSQL VM
resource "azurerm_linux_virtual_machine" "postgresql_vm" {
  name                = var.db_vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_B2s_v2"
  admin_username      = "azureuser"
  admin_ssh_key {
    username   = "azureuser"
    # Use the generated private key for authentication
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  network_interface_ids = [azurerm_network_interface.postgresql_vm_nic.id]

  os_disk {
    name              = "postgresql-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-lts"
    version   = "latest"
  }
}

# Create Network Interface for Flask VM
resource "azurerm_network_interface" "flask_vm_nic" {
  name                = "flask-vm-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_flask.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.flask_vm_public_ip.id  # Associate public IP with the NIC
  }
}

# Create Network Interface for PostgreSQL VM
resource "azurerm_network_interface" "postgresql_vm_nic" {
  name                = "postgresql-vm-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_db.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.postgresql_vm_public_ip.id  # Associate public IP with the NIC
  }
}

# Create Data Disk for PostgreSQL VM
resource "azurerm_managed_disk" "postgresql_data_disk" {
  name                 = "postgresql-datadisk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 8
}

# Attach Data Disk to PostgreSQL VM
resource "azurerm_virtual_machine_data_disk_attachment" "postgresql_data_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.postgresql_data_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.postgresql_vm.id
  lun                = 0
  caching            = "None"
}
