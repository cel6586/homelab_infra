# homelab_infra

Infrastructure code for my homelab: a single server running Proxmox, with VMs built by Terraform and configured by Ansible. See `plan.md` for the goals and `decisions.md` for why things are built this way.

## Architecture

```mermaid
flowchart TB
  visitors["Internet visitors"]
  cf["Cloudflare Tunnel"]
  pc["My PC<br/>(home network)"]
  router["Home router"]

  subgraph host["HP ProDesk: i5-10500T, 32 GB RAM, 512 GB SSD, running Proxmox"]
    subgraph ds["docker-services VM<br/>2 vCPU, 4 GB RAM, 100 GB disk"]
      dsapps["Uptime Kuma, Garage, Dozzle, Portainer,<br/>node_exporter, Healthchecks, Jellyfin,<br/>Traefik, Vaultwarden"]
    end
    subgraph gl["gitlab VM<br/>4 vCPU, 8 GB RAM, 80 GB disk"]
      glapps["GitLab, GitLab runner"]
    end
    subgraph k8s["k8s VM<br/>4 vCPU, 12 GB RAM, 100 GB disk"]
      k8sapps["MicroK8s<br/>game-tracker, Argo CD, Vault, External Secrets,<br/>cert-manager, Traefik, cloudflared,<br/>Prometheus, Grafana, Loki"]
    end
  end

  visitors --> cf
  cf -->|"tunnel to cloudflared on the k8s VM"| host
  pc --> router
  router --> host
```

## How it connects

```mermaid
---
config:
  layout: elk
---
flowchart TB
  visitors["Internet visitors"]
  cf["Cloudflare Tunnel"]
  pc["My PC"]
  github["GitHub<br/>repos, Actions, GHCR"]
  s3["AWS S3"]
  igdb["IGDB"]

  subgraph k8s["k8s VM"]
    runner["GitHub runner"]
    argo["Argo CD"]
    subgraph managed["Managed by Argo CD"]
      cloudflared["cloudflared"]
      certm["cert-manager"]
      eso["External Secrets"]
      vault["Vault"]
      prom["Prometheus,<br/>Grafana"]
      loki["Loki, Alloy"]
    end
    subgraph gt["game-tracker"]
      web["web<br/>2 replicas"]
      api["api<br/>2 replicas"]
      db["Postgres"]
      backupjob["Postgres<br/>backup job"]
    end
  end

  subgraph gl["gitlab VM"]
    gitlab["GitLab"]
    glrunner["GitLab runner"]
    glnode["node_exporter"]
  end

  subgraph ds["docker-services VM"]
    garage["Garage"]
    vw["Vaultwarden"]
    vwb["Vaultwarden<br/>backup script"]
    dsnode["node_exporter"]
    kuma["Uptime Kuma<br/>pings the other VMs,<br/>alerts Discord"]
    other["Also running:<br/>Dozzle, Portainer, Healthchecks,<br/>Jellyfin, Traefik"]
  end

  visitors --> cf --> cloudflared --> web --> api --> db
  api -->|"game search"| igdb
  pc -->|"git push"| github
  pc -->|"web pages, kubectl, Ansible"| k8s
  pc -->|"git push, web pages, Ansible"| gl
  pc -->|"web pages, Ansible"| ds
  github -->|"homelab_infra repo"| argo
  argo -->|"syncs"| managed
  github -->|"deploy job"| runner
  runner -->|"helm upgrade"| gt
  github -->|"images pulled by the cluster"| gt
  vault --> eso
  backupjob -->|"pg_dump"| db
  backupjob --> s3
  backupjob --> garage
  vw --> vwb --> garage
  kuma ~~~ other
  other ~~~ dsnode
  prom -->|"scrapes"| glnode
  prom -->|"scrapes"| dsnode
  gitlab -->|"jobs"| glrunner
  glrunner -.->|"practice pipeline"| gt
```

Vault and External Secrets supply secrets to the cluster, cert-manager issues the certificates, Prometheus, Loki and Alloy monitor everything in the cluster, and `cloudflared` carries the public traffic. Argo CD keeps all of these in sync from this repo.

## Security

- The Cloudflare Tunnel is opened from inside the network, so no ports are open to the internet
- Secrets are in Vault and synced into the cluster by External Secrets. Nothing secret is in git
- cert-manager issues TLS certificates from my own CA for the internal sites
- The VM-level secrets (the GitLab AWS keys, Healthchecks, the Cloudflare DNS token) are in Ansible Vault
- Pull requests to this repo run gitleaks, yamllint, kubeconform and `helm template`. The game-tracker pipeline adds Trivy and CodeQL

## Apps

Apps keep their own deploy code in their own repo, so a change to the code and its Helm chart can go out together.

- **game-tracker:** [repo](https://github.com/cel6586/game-tracker), [Helm chart](https://github.com/cel6586/game-tracker/tree/main/chart). A GitHub Actions workflow tests the code, builds the images, and deploys the chart to the MicroK8s cluster with `helm upgrade --install`.

The Kubernetes namespace and secrets are applied once by hand from `apps/game-tracker/` (the secret files are not in git).
