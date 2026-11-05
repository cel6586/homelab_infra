# Creates one VM for every entry in var.vms by cloning the Ubuntu template.
# IP, user and ssh key are set through cloud-init so ansible can log in right away.
resource "proxmox_virtual_environment_vm" "vm" {
  for_each = var.vms

  name      = each.key
  node_name = var.node_name
  vm_id     = each.value.vm_id

  clone {
    vm_id = var.template_id
  }

  cpu {
    cores = each.value.cores
    type  = "host" # passes the real CPU through, faster than the default emulated one
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = each.value.disk_size
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "${each.value.ip}/${var.network_prefix}"
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      username = "ubuntu"
      keys     = var.ssh_public_keys
    }
  }
  # lets Proxmox see the VM's IP. Needs qemu-guest-agent inside, ansible common.yml installs it
  agent {
    enabled = true
  }
}