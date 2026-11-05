terraform {
  required_version = ">= 1.16.6"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.118.0"
    }
  }
}

# Proxmox API on the ProDesk
provider "proxmox" {
  endpoint = "https://10.0.0.253:8006/"
  insecure = true # proxmox uses a self-signed cert, fine on the home network
}