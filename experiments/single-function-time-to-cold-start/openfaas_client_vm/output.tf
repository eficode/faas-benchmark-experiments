# output ip address
output "ip_address" {
  value = azurerm_linux_virtual_machine.single-function-time-to-cold-start-openfaas-worker.public_ip_address
}
