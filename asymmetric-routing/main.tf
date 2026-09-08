terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

# ##############################################################
# Local values
# ##############################################################

locals {
  name_suffix = "${var.environment}-${var.project_name}"

  tags = {
    environment = "learning"
    purpose     = "azure-troubleshooting"
    case        = "firewall-load-balancer-asymmetric-routing"
  }
}

# ##############################################################
# Resource group
# ##############################################################

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.tags
}

# ##############################################################
# Virtual network
# ##############################################################

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.30.0.0/16"]
  tags                = local.tags
}

# ##############################################################
# Subnets
# ##############################################################

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.30.0.0/26"]
}

resource "azurerm_subnet" "firewall_management" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.30.0.64/26"]
}

resource "azurerm_subnet" "workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.30.1.0/24"]
}

# ##############################################################
# Public IP addresses
# ##############################################################

resource "azurerm_public_ip" "load_balancer" {
  name                = "pip-lb-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_public_ip" "firewall" {
  name                = "pip-fw-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_public_ip" "firewall_management" {
  name                = "pip-fw-management-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# ##############################################################
# Azure Firewall policy
# ##############################################################

# resource "azurerm_firewall_policy" "this" {
#   name                = "afwp-${local.name_suffix}"
#   location            = azurerm_resource_group.this.location
#   resource_group_name = azurerm_resource_group.this.name
#   sku                  = "Basic"
#   tags                 = local.tags
# }

# resource "azurerm_firewall_policy_rule_collection_group" "this" {
#   name               = "rcg-${local.name_suffix}"
#   firewall_policy_id = azurerm_firewall_policy.this.id
#   priority           = 100

#   network_rule_collection {
#     name     = "allow-workload-outbound"
#     priority = 100
#     action   = "Allow"

#     rule {
#       name                  = "allow-http-https-dns"
#       protocols             = ["TCP", "UDP"]
#       source_addresses      = ["10.30.1.0/24"]
#       destination_addresses = ["*"]
#       destination_ports     = ["53", "80", "443"]
#     }
#   }
# }

# ##############################################################
# Azure Firewall
# ##############################################################

# resource "azurerm_firewall" "this" {
#   name                = "afw-${local.name_suffix}"
#   location            = azurerm_resource_group.this.location
#   resource_group_name = azurerm_resource_group.this.name
#   sku_name            = "AZFW_VNet"
#   sku_tier            = "Basic"
#   firewall_policy_id  = azurerm_firewall_policy.this.id
#   tags                = local.tags

#   ip_configuration {
#     name                 = "firewall-ip-configuration"
#     subnet_id            = azurerm_subnet.firewall.id
#     public_ip_address_id = azurerm_public_ip.firewall.id
#   }

#   management_ip_configuration {
#     name                 = "firewall-management-ip-configuration"
#     subnet_id            = azurerm_subnet.firewall_management.id
#     public_ip_address_id = azurerm_public_ip.firewall_management.id
#   }
# }

# ##############################################################
# Route table - intentional asymmetric routing
# ##############################################################

# resource "azurerm_route_table" "workload" {
#   name                = "rt-workload-${local.name_suffix}"
#   location            = azurerm_resource_group.this.location
#   resource_group_name = azurerm_resource_group.this.name
#   tags                = local.tags

#   route {
#     name                   = "default-route-to-firewall"
#     address_prefix         = "0.0.0.0/0"
#     next_hop_type          = "VirtualAppliance"
#     next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
#   }
# }

# resource "azurerm_subnet_route_table_association" "workload" {
#   subnet_id      = azurerm_subnet.workload.id
#   route_table_id = azurerm_route_table.workload.id
# }

# ##############################################################
# Network security group
# ##############################################################

resource "azurerm_network_security_group" "workload" {
  name                = "nsg-workload-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-HTTP-From-Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-From-Internet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-AzureLoadBalancer-Probe"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  subnet_id                 = azurerm_subnet.workload.id
  network_security_group_id = azurerm_network_security_group.workload.id
}

# ##############################################################
# Network interface
# ##############################################################

resource "azurerm_network_interface" "vm" {
  name                = "nic-vm1-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.workload.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.30.1.4"
  }
}

# ##############################################################
# Public Standard Load Balancer
# ##############################################################

# resource "azurerm_lb" "public" {
#   name                = "lb-public-${local.name_suffix}"
#   location            = azurerm_resource_group.this.location
#   resource_group_name = azurerm_resource_group.this.name
#   sku                 = "Standard"
#   tags                = local.tags

#   frontend_ip_configuration {
#     name                 = "public-frontend"
#     public_ip_address_id = azurerm_public_ip.load_balancer.id
#   }
# }

# resource "azurerm_lb_backend_address_pool" "web" {
#   name            = "backend-pool-web"
#   loadbalancer_id = azurerm_lb.public.id
# }

# resource "azurerm_network_interface_backend_address_pool_association" "vm" {
#   network_interface_id    = azurerm_network_interface.vm.id
#   ip_configuration_name   = "internal"
#   backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
# }

# resource "azurerm_lb_probe" "http" {
#   name                = "probe-http"
#   loadbalancer_id     = azurerm_lb.public.id
#   protocol            = "Tcp"
#   port                = 80
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }

# resource "azurerm_lb_rule" "http" {
#   name                           = "rule-http"
#   loadbalancer_id                = azurerm_lb.public.id
#   protocol                       = "Tcp"
#   frontend_port                  = 80
#   backend_port                   = 80
#   frontend_ip_configuration_name = "public-frontend"
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
#   probe_id                       = azurerm_lb_probe.http.id
#   disable_outbound_snat          = true
# }

# # SSH through the Load Balancer public IP on TCP/5001.
# # This connection is expected to be affected by the same asymmetric route.
# resource "azurerm_lb_nat_rule" "ssh" {
#   name                           = "nat-ssh-vm1"
#   resource_group_name            = azurerm_resource_group.this.name
#   loadbalancer_id                = azurerm_lb.public.id
#   protocol                       = "Tcp"
#   frontend_port                  = 5001
#   backend_port                   = 22
#   frontend_ip_configuration_name = "public-frontend"
# }

# resource "azurerm_network_interface_nat_rule_association" "ssh" {
#   network_interface_id  = azurerm_network_interface.vm.id
#   ip_configuration_name = "internal"
#   nat_rule_id            = azurerm_lb_nat_rule.ssh.id
# }

# ##############################################################
# Linux virtual machine
# ##############################################################

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm1-${local.name_suffix}"
  computer_name                   = "vm1"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  size                            = "Standard_B2ats_v2"
  admin_username                  = var.vm_admin_username
  admin_password                  = var.vm_admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.vm.id]
  tags                            = local.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-CLOUD_INIT
    #cloud-config
    package_update: true
    packages:
      - nginx
    write_files:
      - path: /var/www/html/index.html
        permissions: '0644'
        content: |
          Azure Load Balancer troubleshooting lab - VM1
    runcmd:
      - systemctl enable nginx
      - systemctl restart nginx
  CLOUD_INIT
  )

  # depends_on = [
  #   azurerm_firewall_policy_rule_collection_group.this,
  #   azurerm_subnet_route_table_association.workload
  # ]
}

# ##############################################################
# Log Analytics workspace and Azure Firewall diagnostics
# ##############################################################

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# resource "azurerm_monitor_diagnostic_setting" "firewall" {
#   name                           = "diag-firewall"
#   target_resource_id             = azurerm_firewall.this.id
#   log_analytics_workspace_id     = azurerm_log_analytics_workspace.this.id
#   log_analytics_destination_type = "Dedicated"

#   enabled_log {
#     category = "AzureFirewallNetworkRule"
#   }

#   enabled_log {
#     category = "AzureFirewallNatRule"
#   }

#   enabled_metric {
#     category = "AllMetrics"
#   }
# }
