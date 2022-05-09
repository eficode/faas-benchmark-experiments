terraform {
  required_providers {
    mycloud = {
      source  = "hashicorp/aws"
      version = "2.51.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "1.3.0"
    }
  }
}
