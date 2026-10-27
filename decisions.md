# Decisions

## Proxmox on the ProDesk
Decision: Install Proxmox on the whole machine, replacing Windows.
Why: I want to practice Terraform, and Proxmox gives it VMs to create.  I also needed more then 1 VM to work with and this fit well.

## One VM first
Decision: Build the Kubernetes VM first and add the others later.
Why: The game-tracker / kubernetes only needs that one.  Will scale up when more are needed

## Kubernetes and MicroK8s
Decision: Use Kubernetes to Host the game-tracker app.  For kubernetes going to use microk8s
Why: Want to practice and get experience using Kubernetes.  Choosing microk8s its good for a homelab and I have already used it another tutorial.

## Prometheus and Grafana in Kubernetes
Decision: Run Prometheus and Grafana in the cluster, and Uptime Kuma on the Docker services VM.
Why: Get more experience with monitoring and this seems to be the standard way to monitor Kubernetes.  Using uptime kuma to get notified if that VM does go down 

## Loki for logs
Decision: Add Loki to the cluster next to Prometheus and Grafana, and read the logs in Grafana.
Why: Prometheus shows metrics, such as a pod being unhealthy, but not why. Logs give the reason. Loki is lightweight compared with other log stacks and plugs straight into Grafana. It is added after Prometheus and Grafana work, and only if RAM on the `k8s` VM allows.

## Push-based deploys with Helm, no ArgoCD
Decision: Deploy with `kubectl apply`, then a Helm chart, then a CI job running `helm upgrade --install`.
Why: Want to get more experience on helm and I already worked a little with ArgoCd on a previous tutorial

## Postgres backups with pg_dump
Decision: Back up Postgres with a scheduled `pg_dump`, stored off the VM.
Why: The database is the only data that cannot be rebuilt from this repo. A dump is the simple standard for a small app.

## Self-hosted GitLab after Kubernetes
Decision: Run GitLab and a CI runner on their own VM, and move the CI/CD pipelines to it once Kubernetes works.
Why: I want to host my own code and learn GitLab CI/CD, which companies use. Starting on GitHub keeps the first steps simple. It is a heavy program, so it gets its own VM that I can stop when not in use.

## GitLab on Kubernetes: optional practice only
Decision: The real GitLab stays on its own VM. Later I may write the files to deploy GitLab on the Kubernetes cluster with the Helm chart as practice, but keep them in the repo disabled.
Why: GitLab on Kubernetes needs a lot of RAM and would compete with game-tracker, monitoring and Vault on a 12 GB VM. If GitLab ran in the cluster, a broken cluster would also take down the code and pipelines needed to rebuild it. The Helm version is still good Helm and Kubernetes practice, so I can keep it without running it.

## GitLab CI as the CI tool, Jenkins only as optional practice
Decision: Use GitLab CI for the real pipelines. Jenkins may be tried later as practice, for example as a container on the `docker-services` VM, but it is not part of the plan.
Why: GitLab already includes CI, so Jenkins would be a second system to run and update, and it needs 2 GB or more of RAM on a 32 GB machine. Jenkins is still widely used, so it is worth trying once there is time and RAM.

## Docker services on their own VM
Decision: Run Jellyfin/Plex, Uptime Kuma and Watchtower as plain Docker services on a separate VM.
Why: They are simple and do not need Kubernetes. Keeping them apart means rebuilding the Kubernetes VM does not take them down.

## Game server on its own VM, later
Decision: If I host a game server, give it an isolated VM, and only if there is room.
Why: It faces the internet, so it should not share a machine with GitLab or the cluster. It also needs RAM the other VMs may already be using.
