# gitops-platform

A production-style platform lab: Kubernetes (RKE2) on Proxmox, provisioned with Terraform and Ansible and managed with ArgoCD, plus ephemeral AWS EKS environments for automated end-to-end validation.

> **Status:** 🚧 In progress — host bootstrap complete, Terraform provisioning next.

## Why this exists

To build and operate a platform the way it would be done in a regulated, high-availability environment: everything as code, every decision documented, every incident written up.

## Target architecture

| Layer | Tooling |
|---|---|
| Hypervisor | Proxmox VE 9 (single node, homelab) |
| VM provisioning | Terraform (`bpg/proxmox` provider) + cloud-init |
| Node configuration | Ansible |
| Kubernetes | RKE2 — 3 server nodes (etcd quorum) + 2 workers |
| Delivery | ArgoCD (GitOps, app-of-apps / ApplicationSets) |
| Ephemeral cloud validation | AWS EKS via GitHub Actions (OIDC, created and destroyed per run) |
| Observability | Prometheus, Grafana, SLOs with burn-rate alerts |
| Security | Kyverno policies, External Secrets, signed images (cosign) |

## Environments

| Environment | Lifetime | Purpose |
|---|---|---|
| `homelab` (Proxmox + RKE2) | Long-lived | Day-to-day platform operation, upgrades, failure testing |
| `ephemeral-e2e` (AWS EKS) | Minutes per run | Validates AWS-specific integrations (IAM, load balancers, storage) before promotion, then is destroyed |

## Progress

- [x] Proxmox host bootstrap: repositories, DNS, NTP, kernel update
- [x] Network plan with static ranges outside the DHCP pool
- [x] Ubuntu 24.04 cloud-init template (VM 9000)
- [x] Terraform service account with API token
- [ ] Terraform: provision RKE2 VMs
- [ ] Ansible: install RKE2
- [ ] ArgoCD bootstrap
- [ ] Observability and SLOs
- [ ] Ephemeral EKS pipeline

## Repository layout

```
bootstrap/proxmox/   One-time host preparation (runbook + scripts)
infra/proxmox/       Terraform for the homelab VMs
infra/aws/           Terraform for the ephemeral EKS environment
ansible/             Node configuration and RKE2 installation
gitops/              ArgoCD applications (platform add-ons and apps)
docs/adr/            Architecture Decision Records
docs/postmortems/    Blameless postmortems of real incidents
docs/network.md      Network and IP plan
```

## Documentation

- [Network plan](docs/network.md)
- [Proxmox bootstrap runbook](bootstrap/proxmox/README.md)
- [Architecture Decision Records](docs/adr/)
- [Postmortems](docs/postmortems/)
