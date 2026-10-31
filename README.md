# homelab_infra

Infrastructure code for my homelab: a single server running Proxmox, with VMs built by Terraform and configured by Ansible. See `plan.md` for the goals and `decisions.md` for why things are built this way.

## Apps

Apps keep their own deploy code in their own repo, so a change to the code and its Helm chart can go out together.

- **game-tracker:** [repo](https://github.com/cel6586/game-tracker), [Helm chart](https://github.com/cel6586/game-tracker/tree/main/chart). A GitHub Actions workflow tests the code, builds the images, and deploys the chart to the MicroK8s cluster with `helm upgrade --install`.

The Kubernetes namespace and secrets are applied once by hand from `apps/game-tracker/` (the secret files are not in git).
