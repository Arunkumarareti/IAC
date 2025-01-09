# Define the AKS Cluster
resource "azurerm_kubernetes_cluster" "fe_aks_cluster" {
  name                = "fe-aks-cluster-task"
  location            = azurerm_resource_group.Task.location
  resource_group_name = azurerm_resource_group.Task.name
  dns_prefix          = "fe-aks-cluster-task"

  default_node_pool {
    name       = "frontend"
    node_count = 2
    vm_size    = "Standard_B2ms" # Size of VM for each node
    vnet_subnet_id = azurerm_subnet.frontend.id  # Use the backend subnet
    os_disk_size_gb = 30
    os_disk_type    = "Managed"
   # enable_node_public_ip = true
    node_public_ip_enabled = true
  }

  identity {
    type = "SystemAssigned"  # This can be "UserAssigned" if you have a custom managed identity
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"  # Set the SKU of load balancer (Standard or Basic)
    service_cidr       = "10.1.0.0/16"
    dns_service_ip     = "10.1.0.10"
  }

  tags = {
    environment = "dev"
  }
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.fe_aks_cluster.kube_config_raw
  sensitive = true
}


