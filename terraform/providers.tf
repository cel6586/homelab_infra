terraform {
  required_version = ">= 1.16.6"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.118.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://10.0.0.253:8006/"
  insecure = true
}