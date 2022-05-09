module "lambda_deployment" {
  source     = "../../../terraform_modules/aws_lambda"
  instance   = var.instance
  aws_region = var.aws_region
}

# we must provide region config to the provider
provider "aws" {
  region = var.aws_region
}


variable "aws_region" {
  type        = string
  description = "which AWS datacenter/region to use"
  default     = "eu-west-1"
}

variable "instance" {
  type        = string
  description = "unique name of this instance"
  default     = "dummy"
}

output "gateway" {
  value = module.lambda_deployment.invoke_url
}

output "api_key" {
  value     = module.lambda_deployment.api_key
  sensitive = true
}

output "instance" {
  value = var.instance
}
