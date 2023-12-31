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
    source_address_prefix      = "*"#var.my_ip_address
    destination_address_prefix = "*"
  }

  # security_rule {
  #   name                       = "allow_ssh_ip1"
  #   priority                   = 101
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "22"
  #   source_address_prefix      = "213.199.131.149"
  #   destination_address_prefix = "*"
  # }

  # security_rule {
  #   name                       = "allow_ssh_ip2"
  #   priority                   = 102
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "22"
  #   source_address_prefix      = "23.97.244.226"
  #   destination_address_prefix = "*"
  # }

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
    source_address_prefix      = "*"#var.my_ip_address
    destination_address_prefix = "*"
  }

  # security_rule {
  #   name                       = "allow_ssh_ip1"
  #   priority                   = 101
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "22"
  #   source_address_prefix      = "213.199.131.149"
  #   destination_address_prefix = "*"
  # }

  # security_rule {
  #   name                       = "allow_ssh_ip2"
  #   priority                   = 102
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "22"
  #   source_address_prefix      = "23.97.244.226"
  #   destination_address_prefix = "*"
  # }

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

# Generate SSH Key Pair for Flask VM
resource "tls_private_key" "flask_vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Write Private Key for Flask VM to File
resource "local_file" "flask_vm_ssh_private_key" {
  filename = "C:/Users/Roee/.ssh/id_rsa_flask_vm"  # Replace with the desired path on your local machine
  content  = tls_private_key.flask_vm_ssh_key.private_key_pem
}

# Generate SSH Key Pair for PostgreSQL VM
resource "tls_private_key" "postgresql_vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Write Private Key for PostgreSQL VM to File
resource "local_file" "postgresql_vm_ssh_private_key" {
  filename = "C:/Users/Roee/.ssh/id_rsa_postgresql_vm"  # Replace with the desired path on your local machine
  content  = tls_private_key.postgresql_vm_ssh_key.private_key_pem
}

# Create Public IP for Flask VM
resource "azurerm_public_ip" "flask_vm_public_ip" {
  name                = "flask-vm-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Create Public IP for PostgreSQL VM
resource "azurerm_public_ip" "postgresql_vm_public_ip" {
  name                = "postgresql-vm-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Create Flask VM
resource "azurerm_linux_virtual_machine" "flask_vm" {
  name                = var.flask_vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_B2s_v2"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.flask_vm_nic.id]
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    # Use the generated private key for authentication
    public_key = tls_private_key.flask_vm_ssh_key.public_key_openssh
  }

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

  

  provisioner "remote-exec" {
    connection {
    
    type        = "ssh"
    host        = azurerm_public_ip.flask_vm_public_ip.ip_address
    user        = "azureuser"  # The SSH user for your VM
    private_key = tls_private_key.flask_vm_ssh_key.private_key_pem
    # timeout     = "15m"
  }
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3-pip",
      "sudo -H pip3 install --upgrade pip",
      "sudo -H pip3 install flask flask-cors psycopg2-binary",
      "echo 'export DB_PASSWORD=\"${var.db_password}\"' >> ~/.bashrc",
      "echo '${data.template_file.app_py.rendered}' >> app.py",
      "python3 app.py",

      
    ]
    
  }
}


# Create PostgreSQL VM
resource "azurerm_linux_virtual_machine" "postgresql_vm" {
  name                = var.db_vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_B2s_v2"
  admin_username      = "azureuser"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    # Use the generated private key for authentication
    public_key = tls_private_key.postgresql_vm_ssh_key.public_key_openssh
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
  
  

  provisioner "remote-exec" {
    connection {
    
    type        = "ssh"
    host        = azurerm_public_ip.postgresql_vm_public_ip.ip_address
    user        = "azureuser"  # The SSH user for your VM
    private_key = tls_private_key.postgresql_vm_ssh_key.private_key_pem
    # timeout     = "15m"
  }
    inline = [
      "sudo apt-get update",
    "sudo apt-get install -y postgresql postgresql-client",
    "sudo service postgresql start",
    "sleep 10",
    "sudo sed -i '/^# IPv4 local connections:/a host    all             all             10.0.2.0/24             trust' /etc/postgresql/10/main/pg_hba.conf",
    "sudo sed -i \"s/^#listen_addresses = .*$/listen_addresses = '*'/\" /etc/postgresql/10/main/postgresql.conf",
    "sudo service postgresql restart",
    "sudo -u postgres psql -c \"CREATE USER roee WITH SUPERUSER PASSWORD '${var.db_password}';\"",
    "sudo -u postgres psql -c \"CREATE DATABASE weighttrackerdb;\"",
    "sudo -u postgres psql -d weighttrackerdb -c \"CREATE TABLE data (name VARCHAR, weight_value INTEGER, mytime TIMESTAMP);\"",
    "sudo -u postgres psql -c \"\\q\"",
    "sudo service postgresql restart",
    "psql -U roee -d weighttrackerdb;"

      
    ]

  }




  # storage_data_disk {
  #   name              = "datadisk-db"
  #   managed_disk_type = "Standart_LRS"
  #   create_option     = "Empty"
  #   disk_size_gb      = 4
  #   lun               = 1
  # }
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
    private_ip_address            = "10.0.1.10"
    primary                       = true
    # public_ip_address_id          = azurerm_public_ip.postgresql_vm_public_ip.id  # Associate public IP with the NIC
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

data "template_file" "app_py" {
  template = file("${path.module}/app.py")

}
