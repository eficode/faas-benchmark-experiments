# variable "aws_access_key" {}
# variable "aws_secret_key" {}
variable "aws_region" {}

locals {
  src_path = "${path.module}/function_src"
}

# path to lambda function code
# variable "path_to_code" {
# type    = string
# default = "foo/function_src/"
# }

# loacal variables
locals {
  aws_region = "eu-central-1"
}

variable "instance" {
  type        = string
  description = "the unique name of this instance of the module"
}
