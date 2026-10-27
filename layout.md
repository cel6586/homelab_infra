# VM layout

| VM | Job | vCPU | RAM | Disk |
|---|---|---|---|---|
| Proxmox host | the hypervisor itself | n/a | ~2 GB | ~30 GB |
| `k8s` | MicroK8s, game-tracker, monitoring, Vault | 4 | 12 GB | 100 GB |
| `gitlab` | GitLab and runner | 4 | 8 GB | 80 GB |
| `docker-services` | Jellyfin/Plex, Uptime Kuma, Watchtower | 2 | 4 GB | 100 GB |

Total: 26 GB of 32 GB RAM, about 310 GB of 512 GB disk.

## Notes
- Game server VM (later) only if there is RAM left.
- Media: currently stored on a drive on my home PC. Optional: add another storage device later. The `docker-services` VM would mount it as a network share.
