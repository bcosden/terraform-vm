# Configure the Microsoft Azure Provider
# sp name: "azure-cli-2020-03-06-14-52-57"
provider "azurerm" {
    version         = "=2.0.0"
    tenant_id       = var.tenant_id
    subscription_id = var.subscription_id
    client_id       = var.client_id
    client_secret   = var.client_secret
    features {}
}

# Use an existing resource group
data "azurerm_resource_group" "newterraformgroup" {
    name     = var.resource_group
}

# Use an existing subnet
data "azurerm_subnet" "newterraformsubnet" {
    name                 = var.subnet
    resource_group_name  = var.resource_group
    virtual_network_name = var.vnet
}

# Create public IPs
resource "azurerm_public_ip" "newterraformpublicip" {
    name                         = "pip_${random_id.randomId.hex}"
    location                     = var.location
    resource_group_name          = var.resource_group
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Use an existing Network Security Group and rule
data "azurerm_network_security_group" "newterraformnsg" {
    name                = var.nsg
    resource_group_name = var.resource_group
    
}

# Create network interface
resource "azurerm_network_interface" "newterraformnic" {
    name                      = "nic_${random_id.randomId.hex}"
    location                  = var.location
    resource_group_name       = var.resource_group

    ip_configuration {
        name                          = "nicconfig_${random_id.randomId.hex}"
        subnet_id                     = data.azurerm_subnet.newterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.newterraformpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# NSG association
resource "azurerm_network_interface_security_group_association" "newterraformnsgassoc" {
  network_interface_id      = azurerm_network_interface.newterraformnic.id
  network_security_group_id = data.azurerm_network_security_group.newterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = var.resource_group
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "newstorageaccount" {
    name                        = "stordiag${random_id.randomId.hex}"
    resource_group_name         = var.resource_group
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create storage account for File Share
resource "azurerm_storage_account" "newfilestorageaccount" {
    name                        = "filestor${random_id.randomId.hex}"
    resource_group_name         = var.resource_group
    location                    = var.location
    account_tier                = "Premium"
    account_kind                = "FileStorage"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "newterraformvm" {
    name                  = var.vm_name
    location              = var.location
    resource_group_name   = var.resource_group
    network_interface_ids = [azurerm_network_interface.newterraformnic.id]
    size                  = var.sku    
    admin_username        = "azureuser"
    admin_password        = var.vmpassword

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.newstorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
}

data "azurerm_public_ip" "newterraformpublicip" {
  name                = azurerm_public_ip.newterraformpublicip.name
  resource_group_name = var.resource_group
}

output "instance_ip_addr" {
  value       = azurerm_public_ip.newterraformpublicip.ip_address
  description = "The public IP address of the main server instance."
}

output "user_name" {
    value       = azurerm_windows_virtual_machine.newterraformvm.admin_username
    description = "Username"
}
