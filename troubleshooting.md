# Troubleshooting

## Terraform apply failed with a 403 on VM.Clone
`terraform apply` failed on all three VMs with `403 Permission check failed (/vms/9000, VM.Clone)`. The API token had Privilege Separation checked, which gives the token its own permissions instead of using the ones I gave the user. I unchecked it (Datacenter > Permissions > API Tokens > Edit) and the apply worked.

## Ansible couldn't connect: private key permissions too open
Ansible's ping failed with `UNPROTECTED PRIVATE KEY FILE` and `Permissions 0755 ... are too open`. SSH ignores a private key that other users can read, and the copy of my key in WSL had the wrong permissions. `chmod 600 ~/.ssh/homelab` fixed it.

## Ansible couldn't use my SSH key because it has a passphrase
Ansible failed with `ssh_askpass: exec(/usr/bin/ssh-askpass): No such file or directory` and `Permission denied (publickey)` on all three VMs. My `homelab` key has a passphrase, and Ansible runs without a terminal so it can't type it in. I could have used ssh-agent, but that needs me to unlock the key by hand each time, which doesn't work for automating from scratch. I made a separate key with no passphrase just for Ansible (`~/.ssh/homelab_ansible`) and use that instead.

## Ansible ignored ansible.cfg
Ansible ignored `ansible.cfg` and reported an empty hosts list, with the warning `Ansible is being run in a world writable directory`. Linux treats the folder as world writable because it is stored on my Windows drive. I set the environment variable `ANSIBLE_CONFIG` to the path of the file so Ansible uses it anyway.