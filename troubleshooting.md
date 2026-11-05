# Troubleshooting

## Terraform apply failed with a 403 on VM.Clone
`terraform apply` failed on all three VMs with `403 Permission check failed (/vms/9000, VM.Clone)`. The API token had Privilege Separation checked, which gives the token its own permissions instead of using the ones I gave the user. I unchecked it (Datacenter > Permissions > API Tokens > Edit) and the apply worked.

## Ansible couldn't connect: private key permissions too open
Ansible's ping failed with `UNPROTECTED PRIVATE KEY FILE` and `Permissions 0755 ... are too open`. SSH ignores a private key that other users can read, and the copy of my key in WSL had the wrong permissions. `chmod 600 ~/.ssh/homelab` fixed it.

## Ansible couldn't use my SSH key because it has a passphrase
Ansible failed with `ssh_askpass: exec(/usr/bin/ssh-askpass): No such file or directory` and `Permission denied (publickey)` on all three VMs. My `homelab` key has a passphrase, and Ansible runs without a terminal so it can't type it in. I could have used ssh-agent, but that needs me to unlock the key by hand each time, which doesn't work for automating from scratch. I made a separate key with no passphrase just for Ansible (`~/.ssh/homelab_ansible`) and use that instead.

## Ansible ignored ansible.cfg
Ansible ignored `ansible.cfg` and reported an empty hosts list, with the warning `Ansible is being run in a world writable directory`. Linux treats the folder as world writable because it is stored on my Windows drive. I set the environment variable `ANSIBLE_CONFIG` to the path of the file so Ansible uses it anyway.

## The AWS CLI backup pod crashed: CPU does not support x86-64-v2
My first test of the backup job failed in the `upload` container with `Fatal glibc error: CPU does not support x86-64-v2`. The `amazon/aws-cli` image needs newer CPU features, and my VMs used Proxmox's default CPU type (`qemu64`), which hides them from the VM. I added `type = "host"` to the `cpu` block in `main.tf`, which passes the real CPU through, and ran `terraform apply`. The VMs restarted and the backup test uploaded to S3.

## Argo CD apps stuck on Progressing because of the Ingress
The monitoring app in Argo CD never finished syncing and said it was waiting on the Grafana Ingress. Argo CD only calls an Ingress healthy once it has an address, and Traefik never fills one in. I added a custom health check to `apps/argocd/values.yaml` that marks every Ingress as healthy, then ran `helm upgrade` on Argo CD.

## Vault always showed OutOfSync in Argo CD
Argo CD kept saying the vault app was out of sync on `vault-agent-injector-cfg`, no matter how many times I synced. Vault changes that setting by itself after it installs, so it never matches Git. I told Argo CD to ignore that one field with `ignoreDifferences` in `vault.yml`.

## External Secrets sync failed: annotations too long
The external-secrets app failed to sync with `CustomResourceDefinition ... is invalid: metadata.annotations: Too long: may not be more than 262144 bytes`. Some of what it installs is too big for a normal apply. I added `ServerSideApply=true` to the Application. It kept failing until I terminated the stuck sync and ran a new one with Server-Side Apply ticked.

## ExternalSecrets wouldn't sync because Vault was sealed
The ExternalSecrets showed `InvalidProviderConfig` and no secrets were being created. Vault seals itself every time its pod restarts, and External Secrets can't read from a sealed Vault. I unsealed it again with the keys and they synced.

## Alerts firing for kube-proxy, scheduler and controller manager
Right after I set up the Discord alerts I got `KubeProxyDown`, `KubeSchedulerDown` and `KubeControllerManagerDown`. MicroK8s runs those as services on the VM, not as pods, so Prometheus can't find them even though the cluster is fine. I set `kubeProxy`, `kubeScheduler` and `kubeControllerManager` to `enabled: false` in `apps/observability/values.yaml`.
