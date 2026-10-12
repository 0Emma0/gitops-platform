# ADR-0002: Servers run in UTC

- **Status:** Accepted
- **Date:** 2026-10-12

## Context

Logs, metrics and traces are correlated across the hypervisor, Kubernetes nodes, cloud environments and external services. Mixed time zones make incident timelines error-prone, and daylight-saving changes create ambiguous or duplicated timestamps.

## Decision

- Guest VMs and Kubernetes nodes stay in **UTC** (the cloud image default).
- The Proxmox host uses local time (`America/Argentina/Buenos_Aires`) only for operator convenience in the UI; all hosts must be NTP-synchronized.
- Dashboards convert to local time at display time.

## Consequences

- ✅ Timestamps are directly comparable across every system.
- ✅ No daylight-saving surprises in logs or scheduled jobs.
- ⚠️ Operators read UTC in raw logs; dashboards and postmortems state the time zone explicitly.
