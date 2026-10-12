# ADR-0003: Dedicated Proxmox service account for Terraform

- **Status:** Accepted (with known technical debt)
- **Date:** 2026-10-12

## Context

Terraform needs API access to Proxmox. Using `root@pam` would tie automation to a human, full-privilege account that cannot be revoked independently.

## Decision

- Create `terraform@pve` with an API token (`terraform@pve!tf`).
- Store the secret only in a password manager; supply it to Terraform through environment variables, never in code or `.tfvars` committed to Git.
- Grant the built-in `PVEAdmin` role for now.

## Consequences

- ✅ Automation credentials can be rotated or revoked without affecting human access.
- ✅ API actions are attributable to the service account in Proxmox task logs.
- ⚠️ **Technical debt:** `PVEAdmin` exceeds least privilege. Follow-up: define a custom role limited to the privileges Terraform actually uses (VM allocation/clone/config, datastore allocation, SDN use) and re-test.
- ⚠️ Token rotation is manual; procedure documented in the [bootstrap runbook](../../bootstrap/proxmox/README.md).
