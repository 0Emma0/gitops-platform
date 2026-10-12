# ADR-0001: Use Ubuntu cloud images with cloud-init instead of ISO installs

- **Status:** Accepted
- **Date:** 2026-10-12

## Context

Cluster nodes must be created and destroyed repeatedly by Terraform. An ISO is an interactive installer: every VM would need a manual or autoinstall-driven OS installation, which is slow and hard to reproduce.

## Decision

Build a Proxmox template (VM 9000) from the official Ubuntu 24.04 cloud image, customized with `qemu-guest-agent` and an empty `/etc/machine-id`. Each node is a full clone configured at first boot through cloud-init (user, SSH key, static IP, hostname).

## Consequences

- ✅ New nodes are ready in about a minute, configured entirely from code — the same model public clouds use.
- ✅ The guest agent lets Proxmox and Terraform read the VM's IP and detect when it is ready.
- ✅ Truncating `machine-id` guarantees a unique ID per clone (avoids duplicate DHCP client IDs and systemd conflicts).
- ⚠️ The template must be rebuilt periodically to pick up newer images; `bootstrap/proxmox/create-ubuntu-template.sh` makes that repeatable.
- ⚠️ The image checksum is verified before customization; the customized copy can no longer be verified against upstream.
