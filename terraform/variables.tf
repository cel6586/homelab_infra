variable "node_name" {
  description = "Proxmox node that hosts the VM"
  type        = string
  default     = "pve"
}

variable "template_id" {
  description = "The ID of the VM template on proxmox"
  type        = number
  default     = 9000
}

variable "gateway" {
  description = "The gateway of our network"
  type        = string
  default     = "10.0.0.1"
}

variable "network_prefix" {
  description = "The network prefix"
  type        = number
  default     = 24
}

variable "dns_servers" {
  description = "The DNS address to use"
  type        = list(string)
  default     = ["10.0.0.1"]
}

variable "ssh_public_key" {
  description = "Public ssh key"
  type        = string
}

variable "vms" {
  description = " VMs to create"
  type = map(object({
    vm_id     = number
    cores     = number
    memory    = number
    disk_size = number
    ip        = string
  }))
}
