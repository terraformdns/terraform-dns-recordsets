terraform {
  required_version = ">= 0.13.0"

  required_providers {
    dns = {
      source = "hashicorp/dns"
    }
    docker = {
      source = "terraform-providers/docker"
    }
  }
}
