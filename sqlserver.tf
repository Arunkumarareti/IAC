resource "azurerm_mssql_server" "database-server" {
  name                         = "task-database-server"
  resource_group_name          = azurerm_resource_group.Task.name
  location                     = azurerm_resource_group.Task.location
  version                      = "12.0"
  administrator_login          = "admin!"         # Provide a secure login
  administrator_login_password = "Jor4phms!!J0r4phms!!"  # Use a secure password
}

resource "azurerm_mssql_database" "task-database" {
  name                = "task-database"
  server_id         = azurerm_mssql_server.database-server.id
  sku_name            = "S1"
}

resource "azurerm_mssql_firewall_rule" "task-database" {
  name                = "allow-azure-services"
  server_id          = azurerm_mssql_server.database-server.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
