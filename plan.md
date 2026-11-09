# Plans for infrastructure
Creating a homelab: a single always on server (on an HP prodesk) running proxmox.  Will split into several VMs for several different projects.  Everything is built from code in this repo, so it can be rebuilt from scratch

# Goals
- Create and configure every VM from code using terraform, and ansible
- Run the game-tracker app (Fast API, postgres, nginx) on Kubernetes
- Deploy it automatically - A CI job builds the images and uses helm to install it
- Monitor setup with Prometheus and grafana, collect logs with Loki, and use Vault to store secrets
- Document choices, problems and fixes as i go
- After Kubernetes, create my own gitlab to host my own code and switch the CI/CD pipelines to that
- If there is enough space / processing power then create a media server like jellyfin and/or a game server

# Constraints
- Hardware - i5-10500T (6 cores/12 threads) 32gb RAM, 512g ssd.  - Should be able to handle a good chunk of this.  Might not be able to fit later goals
- Start off on home network.  Possibly open up to the internet
- Push-based deploys using helm chart and CI job.


# Proxmox
- Replace windows with Proxmox.  Use terraform to automate creation of VMs, and use ansible to set up what is required on each VM

# VM 1 - Kubernetes with game-tracker
Single node MicroK8s cluster and will host the game-tracker app.  the same VM runs prometheus/grafana for monitoring and vault for secrets and Loki for logs.  Did a CI push with github runner for game-tracker deploy.  Later on changed my mind on homelab deploy and am going to use ARGO cd for that deploy

# VM 2 - GitLab
The second VM will run Gitlab and a CI runner for the pipelines jobs.

# VM 3 - Docker services
This will hold plain Docker services like Jellyfin/Plex and Uptime Kuma.

# VM 4 - Game server
Game server that faces the internet.  If there is a game im wanting to host, and if there is room for it

# Order of work
1. Planning and decisions
2. Install proxmox
3. Setup terraform to create the VMs
4. Setup Ansible to install and configure microk8s
5. Use Helm charts to deploy game-tracker
6. Setup CI Jobs to automate helm install
7. Monitoring and secrets
8. VM 2 and VM3

# out of scope
- No arcoCD / gitops.  Changed mind, going to do ArgoCd for infrastucture repo.  WIll leave game-tracker repo with CI push and github runner for now.  Changed my mind to get more experience with pull based deploy

# Backups
- Only need to back up postgres database. do a postgres dump to another on schedule

# need to figure out
- where do builds run
- network layout - how to reach VM from my desktop and best way to set this up from another machine
- If i want to expose it to the internet, how do i do that, and whats the safest way.
- How to automate the rest of the Kubernetes setup that the push-based CI deploy does not cover (the one-time `kubectl apply` files in `apps/`, monitoring, the runner registration). Options: a CI job in this repo, Ansible, or Argo CD. If Argo CD turns out to be the best course, "No ArgoCD / GitOps" in out of scope changes. Secrets need Vault either way.