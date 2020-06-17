# import variables
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

# ssh key vars
variable "client_pub_key" {}
variable "client_pvt_key" {}
variable "client_ssh_fingerprint" {}

# ip address of the db server
variable "db_server_static_ip" {}

# for variable experiment based client size
variable "openfaas_client_vm_size" {}
