# output ip address
output "ip_address" {
  value = azurerm_linux_virtual_machine.coldstart-identifier-nested-worker.public_ip_address
}
