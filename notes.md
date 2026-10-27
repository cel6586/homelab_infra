# Notes and learnings

## Manual step: installing Proxmox on the ProDesk
The one step that is not in code. Installed from a USB stick with a monitor and keyboard. Used the Graphical installer, wired NIC `nic0` (not the Wi-Fi `nic1`), hostname `pve.homelab.internal`, IP `10.0.0.253/24`, gateway `10.0.0.1`.

## Manual step: building the Ubuntu 24.04 template (VM 9000)
Terraform does not install Ubuntu for each VM. It clones a template that already has Ubuntu on it. Proxmox has no library of ready-made images like a cloud provider does, so I build the template once by hand on the Proxmox host. Terraform then clones it for `k8s`, `gitlab` and `docker-services`.

I used the Ubuntu **cloud image** (`.img`), not the installer ISO. The `.img` is Ubuntu already installed as a disk, with cloud-init built in. An ISO would mean booting the installer, clicking through it, and installing cloud-init myself.

1. Download the image into the folder Proxmox keeps downloaded files in:
   ```bash
   cd /var/lib/vz/template/iso
   wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
   ```
   `noble` is Ubuntu 24.04's codename, `cloudimg` is the VM-ready image, `amd64` is the CPU type. Running `wget` twice leaves a duplicate ending in `.img.1`, which can be deleted.

2. Create an empty VM:
   ```bash
   qm create 9000 --name ubuntu-2404-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
   ```
   `9000` is the VM ID, kept high so templates sit apart from normal VMs. `--net0 virtio,bridge=vmbr0` adds a network card connected to Proxmox's virtual switch, which is how VMs get an address on the `10.0.0.x` network. `--scsihw virtio-scsi-pci` is the disk controller, the virtual hardware that disks plug into.

3. Import the image as the VM's disk:
   ```bash
   qm set 9000 --scsi0 local-lvm:0,import-from=/var/lib/vz/template/iso/noble-server-cloudimg-amd64.img
   ```
   `scsi0` is the first disk slot. `local-lvm` is the storage for VM disks (the `local` storage is for files like this image). The `0` is a placeholder size, the real size comes from the image. Without this step the VM has no disk and nothing to clone (this is what was wrong when `qm list` showed `BOOTDISK 0.00`).

4. Add the cloud-init drive:
   ```bash
   qm set 9000 --ide2 local-lvm:cloudinit
   ```
   A tiny extra drive. When Terraform clones the template it writes the new VM's username, SSH key and IP onto it, and cloud-init inside Ubuntu reads it on first boot. This is how each clone gets its own settings without me logging in. `ide2` is just the slot Proxmox uses by convention for it, it shows up as a virtual CD-ROM.

5. Boot from the disk:
   ```bash
   qm set 9000 --boot order=scsi0
   ```
   The VM started with `order=net0`, which boots from the network and never finds Ubuntu.

6. Add a serial console:
   ```bash
   qm set 9000 --serial0 socket --vga serial0
   ```
   Ubuntu cloud images print their boot output to a serial port. This adds the port and sends the Proxmox console window to it. Without it the console can stay blank even though the VM is running.

7. Convert it to a template:
   ```bash
   qm template 9000
   ```
   Makes the VM clone-only so it can't be booted and changed by accident. Terraform's clone feature needs it.

8. Check it with `qm config 9000`. It should show `scsi0:`, `ide2: ...cloudinit`, `boot: order=scsi0` and `template: 1`. The disk is only 3.5 GB (the size of the image), Terraform sets the real size on each clone.

### Terms
- **Template**: a VM that can only be cloned. Cloning is a copy, which takes seconds.
- **Cloud-init**: a program inside the cloud image that applies first-boot settings (user, SSH key, network) from the cloud-init drive.
- **SCSI / IDE**: disk connection types. Real hardware standards that Proxmox emulates in software. `scsi0` is used for the main disk because virtio-scsi is fast in VMs. `ide2` is used for cloud-init by convention.
- **`local` vs `local-lvm`**: `local` is a folder for files (images, ISOs). `local-lvm` is thin-provisioned storage for VM disks, so a disk only uses the space it has actually written to.

## Manual step: Terraform user, role and API token in Proxmox
Terraform needs to log in to Proxmox to create VMs. Instead of using the `root` password, I made a separate user with only the permissions Terraform needs, and a token for it. If the token ever leaks, only that user is affected and the token can be deleted without changing any password. (Written after the fact, from the standard steps. Fix any details that differ from what I actually typed.)

1. **User**: `TerraformRole@pve`. `@pve` means Proxmox keeps the account itself (unlike `root@pam`, which is a Linux login). It has no password because Terraform logs in with the token.
2. **Role**: a named set of permissions, for example "can clone VMs, create disks, set VM options". Giving a role only what Terraform needs is called least privilege.
3. **Permission (ACL)**: attaches the role to the user on a path, usually `/` (everything). Without this the user exists but can do nothing.
4. **API token**: a key that belongs to the user. Its ID looks like `TerraformRole@pve!tokenname`, and Proxmox shows its **secret** only once, at creation. Terraform sends the ID and secret instead of a password.

The secret is never saved in this repo. It is kept in a password manager, and Terraform reads it from an environment variable or a git-ignored file.

Check what exists with:
```bash
pveum user list
pveum user token list TerraformRole@pve
pveum acl list
```

## Terraform: providers.tf, init and .gitignore

- `terraform/providers.tf`: declares the `bpg/proxmox` provider (`~> 0.118.0`), the endpoint `https://10.0.0.253:8006/`, and `insecure = true` (Proxmox uses a self-signed certificate). `required_version = ">= 1.16.6"` sets the minimum Terraform CLI version.
- The API token is not in any file. It is set per terminal with `$env:PROXMOX_VE_API_TOKEN = "user@realm!tokenname=secret"` so the secret never reaches git.
- Version constraints: `>=` means this version or newer. `~> 0.118.0` allows only 0.118.x patch updates.
- `terraform init` (run inside the `terraform` folder) downloaded provider v0.118.0 into `.terraform/` and created `.terraform.lock.hcl`.
- `.terraform.lock.hcl` pins the exact provider version and stores checksums so a swapped or tampered plugin is rejected. Commit it. `terraform init -upgrade` moves it to a newer allowed version.
- `.gitignore` now ignores `.terraform/` (re-downloadable plugin), `*.tfstate*` (state can hold secrets), `*.tfvars` (variable values may hold secrets) and `crash.log`.
- The other provider seen online, `Telmate/proxmox`, uses `pm_*` settings. They do not work with `bpg/proxmox`.

## Terraform: variables, main.tf and first plan

- `variables.tf` declares the inputs. Shared values have defaults: `node_name` (`pve`), `template_id` (9000), `gateway` (`10.0.0.1`), `network_prefix` (24), `dns_servers`. `ssh_public_key` and `vms` have no default, so their values come from `terraform.tfvars`.
- `vms` is a `map(object({...}))`: one entry per VM with `vm_id`, `cores`, `memory` (MB), `disk_size` (GB) and `ip`. The shape is in `variables.tf`, the real values are in `terraform.tfvars` (git-ignored because it holds setup-specific data).
- Network prefix: `/24` means the first three numbers (`10.0.0`) identify the network, the last one identifies the device. It is joined to each IP as `10.0.0.250/24`. The gateway (`10.0.0.1`) is where traffic for anything outside `10.0.0.x` goes.
- Router DHCP pool was `10.0.0.2` to `10.0.0.253`, which overlapped the static IPs. Ending address changed to `10.0.0.240`. Static range: `.250` k8s, `.251` gitlab, `.252` docker-services, `.253` Proxmox.
- VM IDs: `k8s` 100, `gitlab` 101, `docker-services` 102 (9000 is the template).
- `main.tf` is one `proxmox_virtual_environment_vm` resource with `for_each = var.vms`. `each.key` is the VM name, `each.value` is its object. The label `"vm"` is only a local name.
- Blocks: `clone` (copies template 9000), `cpu`, `memory` (MB), `disk` (`scsi0` on `local-lvm`, resized from 3.5 GB), `network_device` (`vmbr0`), `initialization` (cloud-init).
- Cloud-init is a program in the Ubuntu cloud image that applies settings on first boot. Terraform writes IP, gateway, DNS, user and SSH key onto the clone's cloud-init drive (`ide2`), and the VM configures itself. `datastore_id` is the Proxmox storage that holds that drive (`local-lvm`, same as the template).
- Two different users: `TerraformRole@pve` is the Proxmox API user Terraform logs in with. `ubuntu` is the Linux account cloud-init creates inside each VM, reached with the `homelab` SSH key.
- API token is set as the user environment variable `PROXMOX_VE_API_TOKEN` in the form `TerraformRole@pve!terraform-token=<secret>`. A new terminal is needed after setting it.
- `terraform fmt` fixes formatting, `terraform validate` checks syntax, `terraform plan` shows what would change without changing anything. First plan: 3 to add, 0 to change, 0 to destroy.

## Terraform: first apply, `-parallelism` and the 403 error

- `terraform apply -parallelism=2` runs the apply but limits Terraform to 2 operations at the same time (default is 10). The three VMs do not depend on each other, so by default all three clone at once. Cloning copies a whole disk, so three at once can overload the host's SSD and the Proxmox API and cause timeouts. It only changes speed and load, never the result. The flag is optional.
- `-out=tfplan` saves a plan to a file so `terraform apply tfplan` runs exactly what was reviewed. It is mainly for CI/CD. `tfplan` is in `.gitignore` because plan files can hold sensitive values.
- First apply failed with `403 Permission check failed (/vms/9000, VM.Clone)`. 403 means the token logged in but was refused the action (a failed login is 401). Cause: the token had `privsep` set to `1` (privilege separation), which gives the token its own permission list that started empty. The ACL only covered the user `TerraformRole@pve`, not the token.
- Fix: set `privsep` to `0` so the token uses the same permissions as its user. In the web UI: Datacenter, Permissions, API Tokens, select `terraform-token`, Edit, uncheck Privilege Separation. Same thing on the host: `pveum user token modify TerraformRole@pve terraform-token --privsep 0`. The secret does not change, so `PROXMOX_VE_API_TOKEN` stays valid. Check with `pveum user token list TerraformRole@pve`.
- Stricter alternative: keep `privsep 1` and add an ACL entry for the token itself. More to manage, so not used here.
